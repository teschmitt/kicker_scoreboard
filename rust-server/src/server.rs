use embedded_svc::utils::mutex::Mutex;
use esp32_nimble::{
    utilities::{mutex::RawMutex, BleUuid},
    BLECharacteristic, BLEDevice, BLEServer, BLEService, DescriptorProperties, NimbleProperties,
};
use log::{debug, info};
use std::sync::Arc;

// Stuff that's missing from original implementation:
//   * pAdvertising->setMinPreferred(0x06) interval is not set

pub(crate) trait Server<T> {
    fn new(config: T) -> Self;
    fn send(self: &Self, goals: &str);
}

pub(crate) struct BLEConfig {
    pub(crate) service_uuid: BleUuid,
    pub(crate) characteristic_uuid: BleUuid,
    pub(crate) mode_characteristic_uuid: BleUuid,
}

pub(crate) struct KickerBLE<'a> {
    // device: &'a mut BLEDevice,
    server: &'a mut BLEServer,
    config: BLEConfig,
    goals_characteristic: Option<Arc<Mutex<RawMutex, BLECharacteristic>>>,
    mode_characteristic: Option<Arc<Mutex<RawMutex, BLECharacteristic>>>,
    service: Arc<Mutex<RawMutex, BLEService>>,
}

impl Server<BLEConfig> for KickerBLE<'_> {
    fn new(config: BLEConfig) -> Self {
        let device = BLEDevice::take();
        let server = device.get_server();
        // let mut client_connected = false;

        // create server
        server
            .on_connect(|_| {
                info!("Client connected");
                device
                    .get_advertising()
                    .start()
                    .expect("Could not start advertising on device after connection");
            })
            .on_disconnect(|_| {
                info!("Client disconnected");
            });

        // create and advertise service
        let service = server.create_service(config.service_uuid);

        Self {
            server,
            config,
            goals_characteristic: None,
            mode_characteristic: None,
            service,
        }
    }

    fn send(self: &Self, goals: &str) {
        self.goals_characteristic
            .lock()
            .set_value(goals.as_bytes())
            .notify();
    }
}

impl KickerBLE<'_> {
    fn create_characteristics(&self) {
        let device = BLEDevice::take();

        // create characteristics
        let goals_characteristic = self.service.lock().create_characteristic(
            self.config.characteristic_uuid,
            NimbleProperties::READ | NimbleProperties::NOTIFY,
        );
        let goals_descriptor = goals_characteristic
            .lock()
            .create_descriptor(BleUuid::from_uuid16(0x2902), DescriptorProperties::READ);
        goals_descriptor.lock().set_value(b"Number of Goals");
        debug!("Characteristic 'Number of goals' is set.");

        // mode characteristic. Production = 0, Debug = 1
        let mode_characteristic = self.service.lock().create_characteristic(
            self.config.mode_characteristic_uuid,
            NimbleProperties::WRITE | NimbleProperties::READ,
        );
        mode_characteristic.lock().on_write(move |value, _param| {
            if let Ok(val) = std::str::from_utf8(value) {
                info!("Got new value for mode_characteristic: '{val}'");
                if val == "1" || val.to_lowercase() == "true" || val.to_lowercase() == "debug" {
                    // set server into debug mode
                }
            };
        });
        let mode_descriptor = mode_characteristic
            .lock()
            .create_descriptor(BleUuid::from_uuid16(0x2902), DescriptorProperties::READ);
        mode_descriptor.lock().set_value(b"Operational mode");

        let _ = BLEDevice::set_device_name("Goal Counter");
        device
            .get_advertising()
            .name("Goal server")
            .add_service_uuid(self.config.service_uuid)
            .start()
            .expect("Could not start advertising on device");
    }
}

impl KickerBLE<'_> {
    pub(crate) fn connected_count(self: &Self) -> usize {
        self.server.connected_count()
    }
}
