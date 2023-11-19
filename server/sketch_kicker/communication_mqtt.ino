#ifdef USE_MQTT

//for testing, run this on mac: /opt/homebrew/opt/mosquitto/sbin/mosquitto -c /opt/homebrew/etc/mosquitto/mosquitto.conf

#include <Preferences.h>
#include <WiFi.h>
#include <WiFiAP.h>
#include <ESPmDNS.h>
#include <SPI.h>
#include <PubSubClient.h>
#include <limits.h>


#define MQTT_KEEPALIVE 25

#ifndef USER_INTERACTION_WANTED
#define USER_INTERACTION_WANTED true
#endif
 


//pinout
const int PIN_LED = 2;

bool failed = false;

//wifi
Preferences prefs;
String ssid;
String password;
String clientIP;


// Setup mqtt
IPAddress server(0, 0, 0, 0);
int port = 1883;
WiFiClient espClient;
PubSubClient client(espClient);
const char goalsTopic[] = "goals";



void setupMqtt() {
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_BUTTON, INPUT);

  Serial.println(F(""));
  readPrefs();

  if (ssid.length() == 0 || password.length() == 0) {
    Serial.println(F("No credentials found. Please provide SSID and password via serial console.\n"));
    if (USER_INTERACTION_WANTED) {
      getCredentialsFromInput();
    } else {
      failed = true;
    }
  } else {
    Serial.printf("Got data for SSID %s\n", ssid.c_str());
  }

  if (!failed) {
    //will set failed = true if something goes wrong
    connectToWifi();
  }

  //feedback on LED
  if (failed) {
    onConnectionFailed();
    return;
  } else {
    onConnected();
  }

  if (!MDNS.begin("ESP32_Browser")) {
    Serial.println("Error setting up MDNS responder!");
    while (1) {
      delay(1000);
    }
  }
  while (server[0] == 0) {
    browseService("mqtt", "tcp");
  }
  client.setServer(server, port);
  client.setCallback(callback);
  Serial.printf("\nConnect to MQTT Server: ");
  Serial.print(server);
  Serial.printf("\nusing MQTT Port: ");
  Serial.print(port);
  clientConnected = true;
}

void loopMqtt() {
  client.loop();
}

void savePrefs() {
  prefs.putString("ssid", ssid);
  prefs.putString("password", password);
}

void getCredentialsFromInput() {
  dialoge("Enter SSID:", ssid);
  dialoge("Enter Password:", password);
  savePrefs();
}

void connectToWifi() {
  Serial.println("");
  Serial.printf("Connecting to %s", ssid.c_str());

  WiFi.begin(ssid.c_str(), password.c_str());

  int delayCount = 0;
  while (WiFi.status() != WL_CONNECTED && delayCount <= 20) {
    delay(500);
    delayCount++;
    Serial.print(".");
  }
  Serial.println("");

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("");
    Serial.println("[connect_successful=True] WiFi connected");
    Serial.print("IP address:");
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
        Serial.println("Reset preferences successfully");
      }
    }
    failed = true;
  }
}

void dialoge(String message, String &saveTo) {
  Serial.println(message);

  while (Serial.available() <= 0) {
    delay(100);
  }

  saveTo = Serial.readStringUntil('\n');
  Serial.println(saveTo);
}

void readPrefs() {
  prefs.begin("credentials");
  Serial.println("Reading credentials from preferences...");

  // Check if credentials already available
  ssid = prefs.getString("ssid");
  password = prefs.getString("password");
}

void onConnected() {
  digitalWrite(PIN_LED, 1);
  delay(3000);
  digitalWrite(PIN_LED, 0);
}

void onConnectionFailed() {
  for (int count = 0, d = 100; count < 3000 / d; count++) {
    digitalWrite(PIN_LED, !digitalRead(PIN_LED));
    delay(d);
  }
}

void browseService(const char * service, const char * proto) {
  Serial.printf("Browsing for service _%s._%s.local. ... ", service, proto);
  int n = MDNS.queryService(service, proto);
  if (n == 0) {
    Serial.println("no services found");
  } else {
    Serial.print(n);
    Serial.println(F(" service(s) found"));
    for (int i = 0; i < n; ++i) {
      // Print details for each service found
      Serial.print(F("  "));
      Serial.print(i + 1);
      Serial.print(F(": "));
      Serial.print(MDNS.hostname(i));
      Serial.print(F(" ("));
      Serial.print(MDNS.IP(i));
      server = MDNS.IP(i); // Assign discovered IP to server
      Serial.print(F(":"));
      Serial.print(MDNS.port(i));
      port = MDNS.port(i);
      Serial.println(F(")"));
    }
  }
  Serial.println();
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print(F("\nAttempting MQTT connection..."));
    // Attempt to connect
    if (client.connect(clientIP.c_str())) {
      Serial.println(F("\nsuccessfully connected"));
      // Once connected, publish an announcement...
      client.publish(goalsTopic, "Hello from ESP32!");
      // ... and resubscribe
      client.subscribe(goalsTopic);
    } else {
      Serial.print(F("failed, rc="));
      Serial.print(client.state());
      Serial.println(F(" try again in 5 seconds"));
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  char message[length];
  for (int i = 0; i < length; i++) {
    message[i] = (char)payload[i];
  }
  Serial.printf("Message arrived [%s] %s\n", topic, message);
  onMessageReceived(String(message));
}

void onMessageReceived(String message) {
  Serial.println(F("No message handler implemented!"));
}

void mqttSendGoals(int goals) {
  char buffer[1];
  buffer[0] = (char) goals;
  client.publish(goalsTopic, buffer);
}

#endif