# coffee_vending

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

















#include <ESP8266WiFi.h>
#include <ArduinoJson.h>

// -------- WIFI AP --------
const char* ssid = "Atlanwa_coffee";
const char* password = "12345678";

WiFiServer server(8080);
WiFiClient client;

StaticJsonDocument<256> doc;

unsigned long lastTempSend = 0;

// -------- TEMP AVERAGING --------
float tempSum = 0;
int tempCount = 0;
unsigned long lastSample = 0;
float avgTemp = 0;

// -------- PINS (CHANGE IF NEEDED) --------
#define MAV    D1
#define CBV    D2
#define TBV    D3
#define HWV    D4
#define MHWV   D5
#define WP     D6
#define HEATER D7
#define LS     D0   // input

// -------- PWM --------
#define MP_FWD D8
#define MP_REV D4   // reuse if needed

// -------- TEMP SENSOR --------
#define NTC_PIN A0   // ONLY 1 ADC in ESP8266

// -------- BUFFER --------
char rxBuf[220];
uint16_t rxIndex = 0;
unsigned long lastRx = 0;

// -------- TEMP CONTROL --------
float setTemp = 0;
float currentTemp = 0;

// -------- NTC READ --------
float readTemperature()
{
int adc = analogRead(A0); // 0–1023

if (adc < 5) adc = 5;

float voltage = adc * 3.3 / 1023.0;
float resistance = 10000.0 * (voltage / (3.3 - voltage));

float steinhart;
steinhart = resistance / 10000.0;
steinhart = log(steinhart);
steinhart /= 3950.0;
steinhart += 1.0 / (25.0 + 273.15);
steinhart = 1.0 / steinhart;
steinhart -= 273.15;

return steinhart;
}

// -------- TEMP AVERAGE --------
void updateTempAverage()
{
if(millis() - lastSample >= 200)
{
lastSample = millis();
float t = readTemperature();

    tempSum += t;
    tempCount++;
}

if(millis() - lastTempSend >= 5000)
{
if(tempCount > 0)
avgTemp = tempSum / tempCount;

    tempSum = 0;
    tempCount = 0;
}
}

// -------- JSON PROCESS --------
void processJSON(char *data)
{
DeserializationError error = deserializeJson(doc, data);
if (error) {
Serial.println("ERR JSON");
return;
}

if (doc.containsKey("MAV")) digitalWrite(MAV, doc["MAV"]);
if (doc.containsKey("CBV")) digitalWrite(CBV, doc["CBV"]);
if (doc.containsKey("TBV")) digitalWrite(TBV, doc["TBV"]);
if (doc.containsKey("HWV")) digitalWrite(HWV, doc["HWV"]);
if (doc.containsKey("MHWV")) digitalWrite(MHWV, doc["MHWV"]);
if (doc.containsKey("WP")) digitalWrite(WP, doc["WP"]);
if (doc.containsKey("HEATER")) digitalWrite(HEATER, doc["HEATER"]);

if (doc.containsKey("SETTEMP"))
setTemp = doc["SETTEMP"];

// PWM (0–1023 for ESP8266)
if (doc.containsKey("MP_FWD")) {
int v = doc["MP_FWD"];
analogWrite(MP_FWD, v);
}

if (doc.containsKey("MP_REV")) {
int v = doc["MP_REV"];
analogWrite(MP_REV, v);
}
}

// -------- WIFI READ --------
void readWiFi()
{
if (!client || !client.connected())
{
client = server.available();
if (client)
Serial.println("Client Connected");
return;
}

while (client.available())
{
char c = client.read();
lastRx = millis();

    if (c == '\n' || c == '\r')
    {
      if (rxIndex == 0) return;

      rxBuf[rxIndex] = '\0';
      rxIndex = 0;

      Serial.print("RX: ");
      Serial.println(rxBuf);

      processJSON(rxBuf);

      StaticJsonDocument<50> res;
      res["RESULT"] = "OK";

      Serial.print("TX: ");
      serializeJson(res, Serial);
      Serial.println();

      serializeJson(res, client);
      client.println();

      return;
    }
    else
    {
      if (rxIndex < sizeof(rxBuf) - 1)
        rxBuf[rxIndex++] = c;
    }
}

if (rxIndex > 0 && millis() - lastRx > 60)
{
rxBuf[rxIndex] = '\0';
rxIndex = 0;

    Serial.print("RX: ");
    Serial.println(rxBuf);

    processJSON(rxBuf);

    StaticJsonDocument<50> res;
    res["RESULT"] = "OK";

    Serial.print("TX: ");
    serializeJson(res, Serial);
    Serial.println();

    serializeJson(res, client);
    client.println();
}
}

// -------- HEATER CONTROL --------
void heaterControl()
{
if(setTemp <= 0) return;

currentTemp = avgTemp;

if(currentTemp >= setTemp)
digitalWrite(HEATER, LOW);

if(currentTemp <= (setTemp - 5))
digitalWrite(HEATER, HIGH);
}

// -------- SETUP --------
void setup()
{
Serial.begin(115200);

WiFi.softAP(ssid, password);
server.begin();

Serial.print("AP IP: ");
Serial.println(WiFi.softAPIP());

pinMode(MAV, OUTPUT);
pinMode(CBV, OUTPUT);
pinMode(TBV, OUTPUT);
pinMode(HWV, OUTPUT);
pinMode(MHWV, OUTPUT);
pinMode(WP, OUTPUT);
pinMode(HEATER, OUTPUT);
pinMode(LS, INPUT);

digitalWrite(MAV, LOW);
digitalWrite(CBV, LOW);
digitalWrite(TBV, LOW);
digitalWrite(HWV, LOW);
digitalWrite(MHWV, LOW);
digitalWrite(WP, LOW);
digitalWrite(HEATER, LOW);

Serial.println("READY");
}

// -------- LOOP --------
void loop()
{
readWiFi();
updateTempAverage();
heaterControl();

if(millis() - lastTempSend > 5000)
{
int fl = digitalRead(LS);
lastTempSend = millis();

    StaticJsonDocument<100> tdoc;
    float roundedTemp = round(avgTemp * 10.0) / 10.0;

    tdoc["TEMP"] = String(roundedTemp, 1);
    tdoc["FLOAT"] = String(fl);

    if (client && client.connected())
    {
      Serial.print("TX TEMP: ");
      serializeJson(tdoc, Serial);
      Serial.println();

      serializeJson(tdoc, client);
      client.println();
    }
}
}
