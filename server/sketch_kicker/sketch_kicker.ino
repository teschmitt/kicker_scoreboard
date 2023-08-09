#define USE_BLE

#ifndef SENSOR_CONNECTED
#define SENSOR_CONNECTED true
#endif

#ifndef USE_2_SENSORS
#define USE_2_SENSORS false
#endif

// Pinout
const int PIN_BUTTON = 0;

const int PIN_RECEIVER_1 = GPIO_NUM_32;
const int PIN_SENDER_1 = GPIO_NUM_33;

const int PIN_RECEIVER_2 = GPIO_NUM_34;
const int PIN_SENDER_2 = GPIO_NUM_35;

unsigned long lastMillis = 0;

// thresholds & timers
const int THRESHOLD_DETECT_OBJECT = 10;
const int DETECT_BUFFER_SIZE = 3;
const int WAIT_AFTER_DETECTION = 2000;

// goal detection
unsigned int received1Buffer[DETECT_BUFFER_SIZE];
unsigned int received2Buffer[DETECT_BUFFER_SIZE];

unsigned long lastObjectDetected = 0;
int goals = 0;

// connection
bool clientConnected = false;


void setup() {
  pinMode(PIN_BUTTON, INPUT);

  pinMode(PIN_RECEIVER_1, INPUT);
  pinMode(PIN_SENDER_1, OUTPUT);

  if(USE_2_SENSORS){
    pinMode(PIN_RECEIVER_2, INPUT);
    pinMode(PIN_SENDER_2, OUTPUT);
  }

  Serial.begin(115200);

#ifdef USE_MQTT
  setupMqtt();
#endif

#ifdef USE_BLE
  setupBle();
#endif
}

void loop(){
#ifdef USE_MQTT
  loopMqtt();
#endif
  int pushButtonState = digitalRead(PIN_BUTTON);
  unsigned long ms = millis();

  if(!SENSOR_CONNECTED){
    if(pushButtonState == HIGH){
      onGoal(ms);
    }
    return;
  }

  if(pushButtonState == HIGH){
    digitalWrite(PIN_SENDER_1, HIGH);
    if(USE_2_SENSORS){
       digitalWrite(PIN_SENDER_2, HIGH);
    }
  }else{
    digitalWrite(PIN_SENDER_1, LOW);
    if(USE_2_SENSORS){
       digitalWrite(PIN_SENDER_2, LOW);
    }
  }
  

  if(ms - lastObjectDetected < WAIT_AFTER_DETECTION){
    return;
  }

  unsigned int received1 = analogRead(PIN_RECEIVER_1);
  updateBuffer(received1, received1Buffer, DETECT_BUFFER_SIZE);
  if(USE_2_SENSORS){
    unsigned int received2 = analogRead(PIN_RECEIVER_2);
    updateBuffer(received2, received2Buffer, DETECT_BUFFER_SIZE);
  }

  //Serial.println(received);

  unsigned int avg1 = average(received1Buffer, DETECT_BUFFER_SIZE);
  unsigned int avg2 = average(received2Buffer, DETECT_BUFFER_SIZE);

  Serial.printf("avg1: %d\n", avg1);
  if(USE_2_SENSORS){
    Serial.printf("avg2: %d\n", avg2);
  }

  if(avg1 > THRESHOLD_DETECT_OBJECT || USE_2_SENSORS && avg2 > THRESHOLD_DETECT_OBJECT){
    onGoal(ms);
  }
}

void onGoal(unsigned long timestamp){
  goals++;
  Serial.printf("Goal! %d - 0\n", goals);

  if(clientConnected){
    Serial.println(F("Setting Value and notifying"));
#ifdef USE_MQTT
    mqttSendGoals(goals);
#endif

#ifdef USE_BLE
    bleSendGoals(goals);
#endif
  }

  lastObjectDetected = timestamp;
}

void initBuffers(){
  for(int i=0; i<DETECT_BUFFER_SIZE; i++){
    received1Buffer[i] = 0;
    received2Buffer[i] = 0;
  }
}

void updateBuffer(unsigned int value, unsigned int* array, int length){
  for(int i=0; i<length-1; i++){
    array[i+1] = array[i];
  }
  array[0] = value;
  //Serial.printf("Buffer: %d, %d, %d\n", array[0], array[1], array[2]);
}

unsigned int average(unsigned int* array, int length){
  int sum = 0;       
  double avg;          

   for (int i = 0; i < length; ++i) {
      sum += array[i];
   }
   avg = double(sum) / length;

   return int(avg);
}