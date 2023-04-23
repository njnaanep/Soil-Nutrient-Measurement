#include <ESP8266WiFi.h>
#include <PubSubClient.h>

#include <SoftwareSerial.h>
#include <Wire.h>

const char* ssid 		= "user";	// wifi ssid
const char* password 		=  "pass";	// wifi password
const char* mqttServer 		= "0.0.0.0";	// IP adress Raspberry Pi

const int mqttPort = 1883;
const char* mqttUser 		= "user";	// if you don't have MQTT Username, no need input
const char* mqttPassword 	= "pass";	// if you don't have MQTT Password, no need input

WiFiClient espClient;
PubSubClient client(espClient);

#define RE 4
#define DE 5

#define RX 12 //D5
#define TX 14 //D6

const byte pHFrame[] =  {0x01, 0x03, 0x00, 0x0d, 0x00, 0x01, 0x15, 0xC9}; //ph Level

byte values[11];

bool sending = false;

SoftwareSerial mod(RX, TX);

void setup() { 

  Serial.begin(9600);
  mod.begin(9600);
  pinMode(RE, OUTPUT);
  pinMode(DE, OUTPUT);

  WiFi.begin(ssid, password);

  Serial.println("Connecting to Network");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to the WiFi network");

  client.setServer(mqttServer, mqttPort);
  client.setCallback(callback);

  reconnect();

  if (client.connected()) {
    client.publish("esp8266/Status", "pH Level Sensor Connected");
  }

  getPhLevel();

  delay(3000);
}

void reconnect() {
  while (!client.connected()) {
    Serial.println("Connecting to MQTT...");

    if (client.connect("ESP8266-pH", mqttUser, mqttPassword )) {
      Serial.println("Connected");
      client.subscribe("esp8266/Command");
    } else {
      Serial.print("failed with state ");
      Serial.print(client.state());
      delay(2000);
    }
  }
}

void callback(String topic, byte* payload, unsigned int length) {

  Serial.print("Message arrived in topic: ");
  Serial.println(topic);

  String tempMessage;

  Serial.print("Message:");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
    tempMessage += (char)payload[i];
  }

  Serial.println();
  Serial.println("-----------------------");

  //Set sending condition to true
  if (topic == "esp8266/Command") {
    if (tempMessage == "0") {
      Serial.println("Measuring Soil pH Level");
      sending = true;
    }

    if (tempMessage == "1") {
      sending = false;
    }

  }

}


// Variable for Timer
long now = millis();
long lastMeasure = 0;
float pHValue = 0;

void loop() {
  if (!client.loop()) client.connect("ESP8266-pH", mqttUser, mqttPassword );

  now = millis();
  if (now - lastMeasure > 5000) {
    lastMeasure = now;
    
    pHValue = getPhLevel();
    delay(300); //250
    
    if (!client.connected()) reconnect();
    
    if (sending) client.publish("Soil/pH", String(pHValue).c_str());
  }
  client.loop();
}

float getPhLevel() {
  digitalWrite(DE, HIGH);
  digitalWrite(RE, HIGH);
  delay(10);

  if (mod.write(pHFrame, sizeof(pHFrame)) == 8) {
    digitalWrite(DE, LOW);
    digitalWrite(RE, LOW);

    for (byte i = 0; i < 7; i++) {
      values[i] = mod.read();
    }
  }
  float soil_ph = float(values[4]) / 10;
  
  return soil_ph;
}
