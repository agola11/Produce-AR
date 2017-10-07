#include <Adafruit_MMA8451.h>

Adafruit_MMA8451 mma = Adafruit_MMA8451();

void setup() {
  //start serial transmitter
  Serial.begin(9600);
  
  if (! mma.begin()) {
    Serial.println("Couldnt start accelerometer");
    while (1);
  }
  
  mma.setRange(MMA8451_RANGE_2_G);
  
}

void loop() {
  /* Get a new sensor event */ 
  sensors_event_t event; 
  mma.getEvent(&event);

  /* Display the results (acceleration is measured in m/s^2) */
  Serial.print("X: \t"); Serial.print(event.acceleration.x); Serial.print("\t");
  Serial.print("Y: \t"); Serial.print(event.acceleration.y); Serial.print("\t");
  Serial.print("Z: \t"); Serial.print(event.acceleration.z); Serial.print("\t");
  Serial.println("m/s^2 ");
  
}
