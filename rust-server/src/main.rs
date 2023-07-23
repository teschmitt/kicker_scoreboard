use esp32_nimble::{utilities::BleUuid, uuid128};
use esp_idf_hal::{
    adc::{config::Config, AdcChannelDriver, AdcDriver, Atten11dB},
    gpio::*,
    peripherals::Peripherals,
};
use esp_idf_sys as _; // If using the `binstart` feature of `esp-idf-sys`, always keep this module imported
use log::info;
use server::{BLEConfig, KickerBLE, Server};
use std::{thread, time::Duration};

mod server;

// consts for BLE functionality
const SERVICE_UUID: BleUuid = uuid128!("c03f245f-d01c-4886-850b-408bc53fe63a");
const CHARACTERISTIC_UUID: BleUuid = uuid128!("03524118-dfd4-40d5-8f28-f81e05442bba");

// consts for ADC / photoelectric gate
const THRESHOLD_DETECT_OBJECT: u16 = 50;
const WAIT_AFTER_DETECTION: Duration = Duration::from_secs(2);

fn main() -> anyhow::Result<()> {
    // It is necessary to call this function once. Otherwise some patches to the runtime
    // implemented by esp-idf-sys might not link properly. See https://github.com/esp-rs/esp-idf-template/issues/71
    esp_idf_sys::link_patches();
    // Bind the log crate to the ESP Logging facilities
    esp_idf_svc::log::EspLogger::initialize_default();

    // set up BLE
    let kicker_server = KickerBLE::new(BLEConfig {
        service_uuid: SERVICE_UUID,
        characteristic_uuid: CHARACTERISTIC_UUID,
    });

    // get the peripherals and set them up
    let peripherals = Peripherals::take().unwrap();

    let mut adc = AdcDriver::new(peripherals.adc1, &Config::new().calibration(true))?;
    let mut goal_sensor: esp_idf_hal::adc::AdcChannelDriver<'_, Gpio32, Atten11dB<_>> =
        AdcChannelDriver::new(peripherals.pins.gpio32)?;

    // persistent loop variables
    let mut goals = 0;

    loop {
        let read = adc.read(&mut goal_sensor)?;
        if read > THRESHOLD_DETECT_OBJECT {
            goals += 1;
            info!("GOOOOOOOOAAAAL! {goals} -- Reading: {read}");
            kicker_server.send(goals);
            thread::sleep(WAIT_AFTER_DETECTION);
        };
    }
}
