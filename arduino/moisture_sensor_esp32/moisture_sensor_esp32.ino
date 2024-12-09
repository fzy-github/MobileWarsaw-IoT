#include<Arduino.h>
#include<Wire.h>
#include<BLEDevice.h>
#include<BLEUtils.h>
#include<BLEServer.h>
#include<BLE2902.h>

// BLE Hello Service
#define HELLO_SERVICE_UUID  "C4363802-EC65-4FFA-856B-2B4DAA8CF912"
#define HELLO_CHARACTERISTIC_UUID "CE0DA1CC-0F40-4673-A6A1-C2EC910CED45"

// BLE Moisture Service
#define MOISTURE_SERVICE_UUID  "06803069-F240-448B-B98B-0B357F280281"
#define MOISTURE_CHARACTERISTIC_UUID "0028DA74-2E2A-40BE-9238-7C86EE890804"

// Moisture sensor contst
#define MAX_SENSOR_VALUE 3918
#define MIN_SENSOR_VALUE 966
const int SENSOR_PIN = A0;

// Pointers to our moisture service and characteristic
BLEService *moistureService;
BLECharacteristic *moistureCharacteristic;


class BLECallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* bleServer) {
      Serial.println("[BLE] Connected!");
      // bleServer->startAdvertising(); // restart advertising
    };

    void onDisconnect(BLEServer* bleServer) {
      Serial.println("[BLE] Disconnected, restart advertising!");
      bleServer->startAdvertising(); // restart advertising
    };
};

void setup() {
  Serial.begin(115200);
  Serial.println("[BLE] Setting up BLE Server!");

  BLEDevice::init("Home Moisture Sensor");
  BLEServer *bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new BLECallbacks());
  
  BLEService *helloService = bleServer->createService(HELLO_SERVICE_UUID);
  BLECharacteristic *helloCharacteristic = helloService->createCharacteristic(HELLO_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_READ);
  helloCharacteristic->setValue("Hello from BLE!");
  helloService->start();
  Serial.println("[BLE] Hello Sercvice started");

  moistureService = bleServer->createService(MOISTURE_SERVICE_UUID);
  moistureCharacteristic = moistureService->createCharacteristic(MOISTURE_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  moistureCharacteristic->setValue("-1");
  moistureCharacteristic->addDescriptor(new BLE2902());
  moistureService->start();

  // setup advertising 
  BLEAdvertising *bleAdvertising = BLEDevice::getAdvertising();
  bleAdvertising->addServiceUUID(MOISTURE_SERVICE_UUID);
  bleAdvertising->setScanResponse(true);

  BLEDevice::startAdvertising();
  Serial.println("[BLE] Moisture Sercvice started");
}

void loop() {
  delay(5000);

  int moisture_pct = read_moisture_pct();
  String data(moisture_pct);

  // update characteristic with new value
  moistureCharacteristic->setValue(data);
  moistureCharacteristic->notify();
  Serial.println("[BLE] Moisture characteristic updated");

  // update advertising with new value
  BLEDevice::getAdvertising()->stop();
  BLEAdvertisementData scanResponse = BLEAdvertisementData();
  scanResponse.setName("Home Moisture Sensor");
  scanResponse.setManufacturerData(data);
  BLEDevice::getAdvertising()->setScanResponseData(scanResponse);
  BLEDevice::getAdvertising()->start();
  Serial.println("[BLE] Advertising updated");

}


int clamp(const int minVal, const int maxVal, const int val) {
  return max(minVal, min(val, maxVal));
}

int read_moisture_pct() {
  int value = analogRead(SENSOR_PIN);
  
  // put value between defined mix & max values
  int clamped = clamp(MIN_SENSOR_VALUE, MAX_SENSOR_VALUE, value);

  // convert value to % reading
  int percentage = map(clamped, MIN_SENSOR_VALUE, MAX_SENSOR_VALUE, 100, 0);

  Serial.print("[Sensor] Value: ");
  Serial.print(value);
  Serial.print(", ");
  Serial.print(percentage);
  Serial.println("%");

  return percentage;
}
