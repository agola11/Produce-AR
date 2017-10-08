#include <Adafruit_MMA8451.h>
#include <Arduino.h>
#include <SPI.h>
#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_SPI.h"

#include "BluefruitConfig.h"

#if SOFTWARE_SERIAL_AVAILABLE
  #include <SoftwareSerial.h>
#endif

    #define FACTORYRESET_ENABLE         1
    #define MINIMUM_FIRMWARE_VERSION    "0.6.6"
    #define MODE_LED_BEHAVIOUR          "MODE"

#define MOTOR_PIN 5

//Bluetooth
Adafruit_BluefruitLE_SPI ble(BLUEFRUIT_SPI_CS, BLUEFRUIT_SPI_IRQ, BLUEFRUIT_SPI_RST);

//Accelerometer
Adafruit_MMA8451 mma = Adafruit_MMA8451();
int debounce_ctr;
TimeoutTimer accelTimer = TimeoutTimer();
TimeoutTimer rxTimer = TimeoutTimer();
TimeoutTimer motorTimer = TimeoutTimer();

void error(const __FlashStringHelper*err) {
  Serial.println(err);
  while (1);
}

void setup() {
  //start serial transmitter
  Serial.begin(115200);
  
  if (! mma.begin()) {
    Serial.println("Couldn't start accelerometer");
    while (1);
  }
  mma.setRange(MMA8451_RANGE_4_G);

  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);
  
  /* Initialise the BT module */
  Serial.print(F("Initialising the Bluefruit LE module: "));

  if ( !ble.begin(VERBOSE_MODE) )
  {
    error(F("Couldn't find Bluefruit, make sure it's in CoMmanD mode & check wiring?"));
  }
  Serial.println( F("OK!") );

  if ( FACTORYRESET_ENABLE )
  {
    /* Perform a factory reset to make sure everything is in a known state */
    Serial.println(F("Performing a factory reset: "));
    if ( ! ble.factoryReset() ){
      error(F("Couldn't factory reset"));
    }
  }

  /* Disable command echo from Bluefruit */
  ble.echo(false);

  Serial.println("Requesting Bluefruit info:");
  /* Print Bluefruit information */
  ble.info();

  Serial.println(F("Please use Adafruit Bluefruit LE app to connect in UART mode"));
  Serial.println(F("Then Enter characters to send to Bluefruit"));
  Serial.println();

  ble.verbose(false);  // debug info is a little annoying after this point!

  /* Wait for connection */
  while (! ble.isConnected()) {
      delay(500);
  }
}

void loop() {
  /* Get a new sensor event */ 
  sensors_event_t event; 
  mma.getEvent(&event);
  
  /* Display the results (acceleration is measured in m/s^2) */
  if(accelTimer.expired()){
    if(event.acceleration.z > 32){
      Serial.println("Bump");
      accelTimer.set(90);
        
      ble.println("AT+BLEUARTTX=b");
  
      // check response status
      if (! ble.waitForOK() ) {
        Serial.println(F("Failed to send?"));
      }
    }
  }
  if(rxTimer.expired()){
    // Check for incoming characters from Bluefruit
    ble.println("AT+BLEUARTRX");
    ble.readline();
    if (strcmp(ble.buffer, "OK") == 0) {
      // no data
    }else {
      Serial.print(F("[Recv] ")); Serial.println(ble.buffer);
      ble.waitForOK();
      digitalWrite(MOTOR_PIN,HIGH);
      motorTimer.set(300);
    }
    rxTimer.set(5);
  }
  if(motorTimer.expired()){
    digitalWrite(MOTOR_PIN,LOW);
  }
  delay(3);
}
