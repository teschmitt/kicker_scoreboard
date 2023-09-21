use esp32_nimble::{utilities::BleUuid, uuid128};
use esp_idf_hal::{
    adc::{config::Config, AdcChannelDriver, AdcDriver, Atten11dB},
    gpio::*,
    peripherals::Peripherals,
};
use esp_idf_sys as _; // If using the `binstart` feature of `esp-idf-sys`, always keep this module imported
use log::{error, info};
use sensors::SensorArray;
use server::{BLEConfig, KickerBLE, Server, DEBUG_MODE};
use std::{thread, time::Duration};

mod sensors;
mod server;

/*
Todos:
  - use interrupts to register goals (wait for contiuous ADC to hit main https://github.com/esp-rs/esp-idf-hal/blob/async-drivers/src/adc.rs#L418)
  - output goal events as JSON through generic event characteristic
  - create configuration characteristic and listen to BLE writes
    - parse input for config changes, reset commandm etc.
*/

// consts for BLE functionality
const SERVICE_UUID: BleUuid = uuid128!("c03f245f-d01c-4886-850b-408bc53fe63a");
const CHARACTERISTIC_UUID: BleUuid = uuid128!("03524118-dfd4-40d5-8f28-f81e05442bba");
const MODE_CHARACTERISTIC_UUID: BleUuid = uuid128!("a436bad4-7cd6-44da-bf2c-bf000b1d1218");
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
        mode_characteristic_uuid: MODE_CHARACTERISTIC_UUID,
    });
    if kicker_server.create_characteristics().is_err() {
        error!("Could not create required characteristics, so this will probably be the first of many errors")
    }

    // get the peripherals and set them up
    let peripherals = Peripherals::take().unwrap();

    let home = SensorArray::new(
        "home".to_string(),
        &mut peripherals.adc1,
        vec![
            Box::new(peripherals.pins.gpio32),
            Box::new(peripherals.pins.gpio32),
            Box::new(peripherals.pins.gpio32),
        ],
        500,
    );

    let mut adc_home = AdcDriver::new(peripherals.adc1, &Config::new().calibration(true))?;
    let mut adc_away = AdcDriver::new(peripherals.adc2, &Config::new().calibration(true))?;
    let mut goal_sensor_home: esp_idf_hal::adc::AdcChannelDriver<'_, Gpio32, Atten11dB<_>> =
        AdcChannelDriver::new(peripherals.pins.gpio32)?;
    let mut goal_sensor_away: esp_idf_hal::adc::AdcChannelDriver<'_, Gpio33, Atten11dB<_>> =
        AdcChannelDriver::new(peripherals.pins.gpio33)?;

    // let home = SensorArray::new("home".to_string(), vec![])

    // persistent loop variables
    let mut goals = 0;

    loop {
        let read_home = adc_home.read(&mut goal_sensor_home)?;
        let read_away = adc_away.read(&mut goal_sensor_away)?;

        if read_home > THRESHOLD_DETECT_OBJECT {
            goals += 1;
            info!(
                "GOAL! {goals} -- Reading: {read_home} -- sent to {} connected clients",
                kicker_server.connected_count()
            );
            let output_str = if DEBUG_MODE.lock().get() {
                format!("{read_home},{goals}")
            } else {
                goals.to_string()
            };
            kicker_server.send(&output_str);
            thread::sleep(WAIT_AFTER_DETECTION);
        };
        if read_away > THRESHOLD_DETECT_OBJECT {
            goals += 1;
            info!(
                "GOAL! {goals} -- Reading: {read_away} -- sent to {} connected clients",
                kicker_server.connected_count()
            );
            let output_str = if DEBUG_MODE.lock().get() {
                format!("{read_away},{goals}")
            } else {
                goals.to_string()
            };
            kicker_server.send(&output_str);
            thread::sleep(WAIT_AFTER_DETECTION);
        };
    }
}
