#ifdef USE_BLE

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID "c03f245f-d01c-4886-850b-408bc53fe63a"
#define CHARACTERISTIC_UUID "03524118-dfd4-40d5-8f28-f81e05442bba"

BLEServer *pServer;
BLEService *pService;
BLECharacteristic *goalsCharacteristic;

class GoalServerCallback: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println(F("Device connected"));
      clientConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println(F("Device Disconnected"));
      clientConnected = false;
    }
};

class GoalsCharacteristicCallbacks: public BLECharacteristicCallbacks{
  	void onRead(BLECharacteristic* pCharacteristic){
      //Serial.printf("Reading characteristic %d\n", pCharacteristic->getValue());
    }
	  void onWrite(BLECharacteristic* pCharacteristic){
       Serial.printf("Writing characteristic %s\n", pCharacteristic->toString());
    }
};


void setupBle(){
  Serial.println(F("Setting up BLE..."));

  BLEDevice::init("Goal Counter");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new GoalServerCallback());
  pService = pServer->createService(SERVICE_UUID);

  goalsCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_READ);
  BLEDescriptor *goalsDescriptor = new BLEDescriptor(BLEUUID((uint16_t)0x2903));

  goalsDescriptor->setValue("Number of Goals");
  goalsCharacteristic->addDescriptor(goalsDescriptor);
  goalsCharacteristic->setValue(goals);
  goalsCharacteristic->setCallbacks(new GoalsCharacteristicCallbacks());
 
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  BLEDevice::startAdvertising();
}

void bleSendGoals(int goals){
  goalsCharacteristic->setValue(goals);
  goalsCharacteristic->notify();
}

#endif
