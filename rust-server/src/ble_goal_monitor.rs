use embedded_svc::utils::mutex::Mutex;
use esp32_nimble::{
    utilities::{mutex::RawMutex, BleUuid},
    BLECharacteristic, BLEDevice, BLEServer, BLEService, DescriptorProperties, NimbleProperties,
};
use log::info;
use std::sync::Arc;

// Stuff that's missing from original implementation:
//   * device does not have a name since BLEDevice::set_device_name() has weird call (see https://taks.github.io/esp32-nimble/esp32_nimble/struct.BLEDevice.html)
//   * no global clientConnected is set or unset on connection/disconnection
//   * pAdvertising->setMinPreferred(0x06) interval is not set

pub(crate) struct KickerBLE<'a> {
    // device: &'a mut BLEDevice,
    _server: &'a mut BLEServer,
    pub(crate) service: Arc<Mutex<RawMutex, BLEService>>,
}

impl KickerBLE<'_> {
    pub(crate) fn new(service_uuid: BleUuid) -> Self {
        let device = BLEDevice::take();
        let _server = device.get_server();
        // let mut client_connected = false;

        _server
            .on_connect(|_| {
                info!("Client connected");
                info!("Multi-connect support: start advertising");
                // TBD: is this really necessary on connect of each client? Or rather once centrally during startup
                device
                    .get_advertising()
                    .start()
                    .expect("Could not start advertising on device after connection");
            })
            .on_disconnect(|_| {
                info!("Client disconnected");
            });
        let service = _server.create_service(service_uuid);
        device
            .get_advertising()
            .name("Goal server")
            // .scan_response(true)
            .add_service_uuid(service_uuid)
            .start()
            .expect("Could not start advertising on device");
        Self { _server, service }
    }
}

pub(crate) struct BLEGoalMonitor {
    pub(crate) goals_characteristic: Arc<Mutex<RawMutex, BLECharacteristic>>,
}

impl BLEGoalMonitor {
    pub fn new(kicker_ble: KickerBLE, characteristic_uuid: BleUuid) -> Self {
        let goals_characteristic = kicker_ble.service.lock().create_characteristic(
            characteristic_uuid,
            NimbleProperties::READ | NimbleProperties::NOTIFY | NimbleProperties::INDICATE,
        );
        let goals_descriptor = goals_characteristic
            .lock()
            .create_descriptor(BleUuid::from_uuid16(0x2903), DescriptorProperties::READ);
        goals_descriptor.lock().set_value(b"Number of Goals");

        BLEGoalMonitor {
            goals_characteristic,
        }
    }

    pub(crate) fn send(self: &Self, goals: u32) {
        self.goals_characteristic
            .lock()
            .set_value(goals.to_string().as_bytes())
            .notify();
    }
}
