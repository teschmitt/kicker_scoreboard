use esp_idf_hal::{adc, gpio, peripheral};
use esp_idf_sys::EspError;

// new trait without Sized
pub trait UnsizedPin {
    fn pin(&self) -> i32;
}

pub struct PinWrapper<T: gpio::Pin> {
    pub inner: Box<T>,
}

impl<T: gpio::Pin> PinWrapper<T> {
    pub fn new(inner: T) -> Self {
        Self {
            inner: Box::new(inner),
        }
    }
}

impl<T: gpio::Pin> UnsizedPin for PinWrapper<T> {
    fn pin(&self) -> i32 {
        self.inner.pin()
    }
}

pub struct IrSensorArray<'a, T: adc::Adc> {
    adc: &'a Box<adc::AdcDriver<'a, T>>,
    pins: Vec<Box<dyn UnsizedPin>>,
    threshold: u16,
}

impl<'a, T: adc::Adc> IrSensorArray<'a, T> {
    pub fn new(
        adc: &'a Box<adc::AdcDriver<'_, T>>,
        pins: Vec<Box<dyn UnsizedPin>>,
        threshold: u16,
    ) -> Self {
        Self {
            adc,
            pins,
            threshold,
        }
    }
}

/// Utility method to make getting boxed GPIO pins easier
pub fn get_wrapped_pin<T: gpio::Pin>(pin: T) -> Box<dyn UnsizedPin> {
    Box::new(PinWrapper::new(pin))
}

// pub struct SenArr<'a, ADC: Adc, ADC1ChannelPin: gpio::ADCPin, ATTEN> {
//     pub adc: AdcDriver<'a, ADC>,
//     pub sensors: Vec<Box<AdcChannelDriver<'a, ADC1ChannelPin, ATTEN>>>,
//     pub thresh: u16,
// }
//
// impl<'a, ADC: Adc, T: gpio::ADCPin, ATTEN: Attenuation<T::Adc>> SenArr<'a, ADC, T, ATTEN> {
//     pub fn new(
//         adc: impl Peripheral<P = ADC> + 'a,
//         pins: Vec<Box<&mut dyn UnsizedPin>>,
//         thresh: u16,
//     ) -> Result<Self, EspError> {
//         let mut sensors = Vec::new();
//         let adc = AdcDriver::new(adc, &adc::config::Config::new().calibration(true))?;
//         for pin in pins {
//             let sensor: Box<AdcChannelDriver<'a, T, ATTEN>> = Box::new(AdcChannelDriver::new(pin)?);
//             sensors.push(sensor);
//         }
//         Ok(SenArr {
//             adc,
//             sensors,
//             thresh,
//         })
//     }
// }
