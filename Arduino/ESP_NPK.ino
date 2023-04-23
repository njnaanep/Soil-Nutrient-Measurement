#include <ESP8266WiFi.h>
#include <PubSubClient.h>

#include <SoftwareSerial.h>
#include <Wire.h>

const char* ssid 		= "user";	// wifi ssid
const char* password 		= "pass";	// wifi password
const char* mqttServer 		= "0.0.0.0";	// IP adress Raspberry Pi

const int mqttPort 		= 1883;
const char* mqttUser 		= "user";	// if you don't have MQTT Username, no need input
const char* mqttPassword 	= "pass";	// if you don't have MQTT Password, no need input

WiFiClient espClient;
PubSubClient client(espClient);

#define RE 4
#define DE 5

#define RX 12 //D5
#define TX 14 //D6

const byte nFrame[] = {0x01, 0x03, 0x00, 0x1e, 0x00, 0x01, 0xe4, 0x0c}; //NITROGEN
const byte pFrame[] = {0x01, 0x03, 0x00, 0x1f, 0x00, 0x01, 0xb5, 0xcc}; //PHOSPHORUS
const byte kFrame[] =  {0x01, 0x03, 0x00, 0x20, 0x00, 0x01, 0x85, 0xc0}; //POTASSSIUM

byte values[11];
SoftwareSerial mod(RX, TX);

bool sending = false;

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
    client.publish("esp8266/Status", "NPK Sensor Connected");
  }

  getData();
  delay(3000);
}

void reconnect() {
  while (!client.connected()) {
    Serial.println("Connecting to MQTT...");

    if (client.connect("ESP8266-NPK", mqttUser, mqttPassword )) {
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
      Serial.println("Measuring Soil NPK Content");
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

void loop() {
  if (!client.loop()) client.connect("ESP8266-NPK", mqttUser, mqttPassword );

  now = millis();
  if (now - lastMeasure > 5000) {
    lastMeasure = now;
    
    String NPK = getData();
    
    if (!client.connected()) reconnect();
    
    if (sending) client.publish("Soil/NPK", NPK.c_str());
    
  }
  client.loop();
}

String getData() {
  byte nValue, pValue, kValue;
  String NPK = "";

  nValue = getNitrogen();
  delay(250);

  pValue = getPhosphorus();
  delay(250);

  kValue = getPotassium();
  delay(250);

  NPK = String(nValue) + "," + String(pValue) + "," + String(kValue);

  return NPK;
}

byte getNitrogen() {
  digitalWrite(DE, HIGH);
  digitalWrite(RE, HIGH);
  delay(10);

  if (mod.write(nFrame, sizeof(nFrame)) == 8) {
    digitalWrite(DE, LOW);
    digitalWrite(RE, LOW);

    for (byte i = 0; i < 7; i++) {
      values[i] = mod.read();
    }
  }

  return values[4];
}

byte getPhosphorus() {
  digitalWrite(DE, HIGH);
  digitalWrite(RE, HIGH);
  delay(10);

  if (mod.write(pFrame, sizeof(pFrame)) == 8) {
    digitalWrite(DE, LOW);
    digitalWrite(RE, LOW);

    for (byte i = 0; i < 7; i++) {
      values[i] = mod.read();
    }
  }

  return values[4];
}

byte getPotassium() {
  digitalWrite(DE, HIGH);
  digitalWrite(RE, HIGH);
  delay(10);

  if (mod.write(kFrame, sizeof(kFrame)) == 8) {
    digitalWrite(DE, LOW);
    digitalWrite(RE, LOW);

    for (byte i = 0; i < 7; i++) {
      values[i] = mod.read();
    }
  }

  return values[4];
}
