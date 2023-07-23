use embedded_svc::utils::mutex::Mutex;
use esp32_nimble::{
    utilities::{mutex::RawMutex, BleUuid},
    BLECharacteristic, BLEDevice, BLEServer, BLEService, DescriptorProperties, NimbleProperties,
};
use log::{debug, info};
use std::sync::Arc;

// Stuff that's missing from original implementation:
//   * no global clientConnected is set or unset on connection/disconnection
//   * pAdvertising->setMinPreferred(0x06) interval is not set

pub(crate) trait Server<T> {
    fn new(config: T) -> Self;
    fn send(self: &Self, goals: u32);
}

pub(crate) struct BLEConfig {
    pub(crate) service_uuid: BleUuid,
    pub(crate) characteristic_uuid: BleUuid,
}

pub(crate) struct KickerBLE<'a> {
    // device: &'a mut BLEDevice,
    _server: &'a mut BLEServer,
    goals_characteristic: Arc<Mutex<RawMutex, BLECharacteristic>>,
    _service: Arc<Mutex<RawMutex, BLEService>>,
}

impl Server<BLEConfig> for KickerBLE<'_> {
    fn new(config: BLEConfig) -> Self {
        let device = BLEDevice::take();
        let _server = device.get_server();
        // let mut client_connected = false;

        // create server
        _server
            .on_connect(|_| {
                info!("Client connected. Multi-connect support: start advertising");
                device
                    .get_advertising()
                    .start()
                    .expect("Could not start advertising on device after connection");
            })
            .on_disconnect(|_| {
                info!("Client disconnected");
            });

        // create and advertise service
        let _service = _server.create_service(config.service_uuid);

        // create characteristic
        let goals_characteristic = _service.lock().create_characteristic(
            config.characteristic_uuid,
            NimbleProperties::READ | NimbleProperties::NOTIFY,
        );
        let goals_descriptor = goals_characteristic
            .lock()
            .create_descriptor(BleUuid::from_uuid16(0x2903), DescriptorProperties::READ);
        goals_descriptor.lock().set_value(b"Number of Goals");
        debug!("Characteristic 'Number of goals' is set.");

        let _ = BLEDevice::set_device_name("Goal Counter"); // ignore error
        device
            .get_advertising()
            .name("Goal server")
            .add_service_uuid(config.service_uuid)
            .start()
            .expect("Could not start advertising on device");

        Self {
            // device,
            _server,
            goals_characteristic,
            _service,
        }
    }

    fn send(self: &Self, goals: u32) {
        self.goals_characteristic
            .lock()
            .set_value(goals.to_string().as_bytes())
            .notify();
    }
}
