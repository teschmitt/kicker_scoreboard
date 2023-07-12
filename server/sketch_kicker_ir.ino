//#include <Preferences.h>
//#include <WiFi.h>
//#include <WiFiAP.h>
//#include <ESPmDNS.h>

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>


#ifndef USER_INTERACTION_WANTED
#define USER_INTERACTION_WANTED true
#endif

#ifndef ONLY_READS
#define ONLY_READS true
#endif

#define MQTT_KEEPALIVE 25
#define SERVICE_UUID "c03f245f-d01c-4886-850b-408bc53fe63a"
#define CHARACTERISTIC_UUID "03524118-dfd4-40d5-8f28-f81e05442bba"
#define RCHARACTERISTIC_UUID "65dcf7da-20da-11ee-be56-0242ac120002"

const int led1 =  2; 
//Preferences prefs;

String ssid;
String password;

String clientIP;
bool failed = false;
bool keyPressed = false;

unsigned long keyPressedStart = ULONG_MAX;
unsigned long lastBlink = 0;
int ledState = LOW;

// Setup mqtt
//WiFiClient espClient;

// Key Button
const int pushButton = 0;

// Pinout
const int pinReceiver = GPIO_NUM_32;
const int pinSender = GPIO_NUM_33;

unsigned long lastMillis = 0;

//thresholds & timers
const int THRESHOLD_DETECT_OBJECT = 2;
const int TIME_DETECT_OBJECT = 10;
const int WAIT_AFTER_DETECTION = 2000;

unsigned long lastStartDetected = 0;
unsigned long lastObjectDetected = 0;

int goals = 0;
bool deviceConnected = false;

BLEServer *pServer;
BLEService *pService;
BLECharacteristic *goalsCharacteristic;
BLECharacteristic *randomCharacteristic;

class GoalServerCallback: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println(F("Device connected"));
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println(F("Device Disconnected"));
      deviceConnected = false;
    }
};

class GoalsCharacteristicCallbacks: public BLECharacteristicCallbacks{
  	void onRead(BLECharacteristic* pCharacteristic){
      Serial.printf("Reading characteristic %d\n", pCharacteristic->getValue());
    }
	  void onWrite(BLECharacteristic* pCharacteristic){
       Serial.printf("Writing characteristic %s\n", pCharacteristic->toString());
    }
};


void setup() {
  pinMode(led1, OUTPUT);
  pinMode(pushButton, INPUT);
  pinMode(pinReceiver, INPUT);
  pinMode(pinSender, OUTPUT);

  Serial.begin(115200);

  Serial.println("");
  setupBle();
  //readPrefs();

  /*if (ssid.length() == 0 || password.length() == 0) {
    Serial.println("[credentials_found=False] No credentials found. Please provide SSID and password via serial console.\n");
    if (USER_INTERACTION_WANTED) {
      getCredentialsFromInput();
    } else {
      failed = true;
    }
  } else {
    Serial.printf("[credentials_found=True] Got data for SSID %s", ssid.c_str());
  }
  if (!failed) {
    //will set failed = true if something goes wrong
    connectToWifi();
  }*/
}

void setupBle(){
  Serial.println(F("Setting up BLE..."));

  BLEDevice::init("Goal Counter");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new GoalServerCallback());
  pService = pServer->createService(SERVICE_UUID);

  
  goalsCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_READ|BLECharacteristic::PROPERTY_INDICATE);
  randomCharacteristic = pService->createCharacteristic(RCHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY|BLECharacteristic::PROPERTY_READ);
  BLEDescriptor *goalsDescriptor = new BLEDescriptor(BLEUUID((uint16_t)0x2903));

  goalsDescriptor->setValue("Number of Goals");
  goalsCharacteristic->addDescriptor(goalsDescriptor);
  goalsCharacteristic->setValue({goals});
  goalsCharacteristic->setCallbacks(new GoalsCharacteristicCallbacks());

 
  pService->start();
  // BLEAdvertising *pAdvertising = pServer->getAdvertising();  // this still is working for backward compatibility
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  //pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Characteristic defined! Now you can read it in your phone!");
}

void loop(){
  int pushButtonState = digitalRead(pushButton);
  if(pushButtonState == HIGH){
    digitalWrite(pinSender, HIGH);
  }else{
    digitalWrite(pinSender, LOW);
  }

  unsigned long ms = millis();

  if(ms - lastObjectDetected < WAIT_AFTER_DETECTION){
    return;
  }

  unsigned int received = analogRead(pinReceiver);

  if(received > THRESHOLD_DETECT_OBJECT && lastStartDetected == 0){
    lastStartDetected = ms;
    //Serial.printf("Over threshold (%d) -> lastStartDetected=%d\n", received, lastStartDetected);
  }

  if(received <= THRESHOLD_DETECT_OBJECT && lastStartDetected > 0){
    lastStartDetected = 0;
    //Serial.println("Reset lastStartDetected");
  }

  if(lastStartDetected == 0){
    return;
  }

  //Serial.printf("Time since last start detected: %d\n", ms - lastStartDetected);

  if(ms - lastStartDetected > TIME_DETECT_OBJECT){
    goals++;
    Serial.printf("Goal! %d - 0\n", goals);
    //TODO: on object detected

    if(deviceConnected){
      //TODO: maybe something smarter, caching?
      Serial.println(F("Setting Value and notifying"));
      goalsCharacteristic->notify();
    }

    lastStartDetected = 0;
    lastObjectDetected = ms;
  }

  //Serial.printf("Received through reader: %d\n", received);
}

void savePrefs() {
  //prefs.putString("ssid", ssid);
  //prefs.putString("password", password);
}

void getCredentialsFromInput() {
  dialoge("Enter SSID:", ssid);
  dialoge("Enter Password:", password);
  savePrefs();
}

/*void connectToWifi() {
  Serial.println(F(""));
  Serial.printf("Connecting to %s", ssid.c_str());

  WiFi.begin(ssid.c_str(), password.c_str());

  int delayCount = 0;
  while (WiFi.status() != WL_CONNECTED && delayCount <= 20) {
    delay(500);
    delayCount++;
    Serial.print(F("."));
  }
  Serial.println(F(""));

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(F(""));
    Serial.println(F("[connect_successful=True] WiFi connected"));
    Serial.print(F("IP address:"));
    Serial.println(WiFi.localIP());
    clientIP = WiFi.localIP().toString();
  } else {
    Serial.printf("[connect_successful=False] Couldn't connect to WiFi %s. Is the data correct?\n", ssid.c_str());
    if (USER_INTERACTION_WANTED) {
      // if the user wants, they can reset the preference data
      String resetAnswer;
      dialoge("Do you want to reset the preference data? [y/n]", resetAnswer);
      resetAnswer.toLowerCase();
      if (resetAnswer.equals("y")) {
        ssid = "";
        password = "";
        savePrefs();
        Serial.println(F("Reset preferences successfully"));
      }
    }
    failed = true;
  }
}*/

void dialoge(String message, String &saveTo) {
  Serial.println(message);

  while (Serial.available() <= 0) {
    delay(100);
  }

  saveTo = Serial.readStringUntil('\n');
  Serial.println(saveTo);
}

/*void readPrefs() {
  prefs.begin("credentials");
  Serial.println(F("Reading credentials from preferences..."));

  // Check if credentials already available
  ssid = prefs.getString("ssid");
  password = prefs.getString("password");
}*/

