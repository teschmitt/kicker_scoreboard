#ifndef SENSOR_CONNECTED
#define SENSOR_CONNECTED true
#endif

// Pinout
const int PIN_BUTTON = 0;
const int PIN_RECEIVER = GPIO_NUM_32;
const int PIN_SENDER = GPIO_NUM_33;

unsigned long lastMillis = 0;

// thresholds & timers
const int THRESHOLD_DETECT_OBJECT = 2;
const int TIME_DETECT_OBJECT = 10;
const int WAIT_AFTER_DETECTION = 2000;

// goal detection
unsigned long lastStartDetected = 0;
unsigned long lastObjectDetected = 0;
int goals = 0;

// connection
bool clientConnected = false;


void setup() {
  pinMode(PIN_BUTTON, INPUT);
  pinMode(PIN_RECEIVER, INPUT);
  pinMode(PIN_SENDER, OUTPUT);

  Serial.begin(115200);

  setupMqtt();
}

void loop(){
  loopMqtt();
  int pushButtonState = digitalRead(PIN_BUTTON);
  unsigned long ms = millis();

  if(!SENSOR_CONNECTED){
    if(pushButtonState == HIGH){
      onGoal(ms);
    }
    return;
  }

  if(pushButtonState == HIGH){
    digitalWrite(PIN_SENDER, HIGH);
  }else{
    digitalWrite(PIN_SENDER, LOW);
  }

  

  if(ms - lastObjectDetected < WAIT_AFTER_DETECTION){
    return;
  }

  unsigned int received = analogRead(PIN_RECEIVER);

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
    onGoal(ms);
  }

  //Serial.printf("Received through reader: %d\n", received);
}

void onGoal(unsigned long timestamp){
  goals++;
  Serial.printf("Goal! %d - 0\n", goals);
  //TODO: on object detected

  if(clientConnected){
    Serial.println(F("Setting Value and notifying"));
    sendGoals(goals);
    //TODO: send/publish
  }

  lastStartDetected = 0;
  lastObjectDetected = timestamp;
}