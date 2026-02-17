#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>
// testing times
unsigned long startMillis;
unsigned long currentMillis;
unsigned long period = 4000;  //the value is a number of milliseconds
int fakeHR = 40;
int count = 0;
int num = 20;

bool testHR = false;

// No other Address options.
#define DEF_ADDR 0x55

#define BUZZER 12

// Reset pin, MFIO pin
const int resPin = 4;
const int mfioPin = 5;

// Takes address, reset pin, and MFIO pin.
SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin); 

bioData body;

void setup(){

  Serial.begin(115200);
  startMillis = millis();
  pinMode(BUZZER, OUTPUT);

  
  Wire.begin();
  int result = bioHub.begin();
  //if (!result)
    //Serial.println("Sensor started!");
  //else
    //Serial.println("Could not communicate with the sensor!!!");

  //Serial.println("Configuring Sensor...."); 
  int error = bioHub.configBpm(MODE_ONE); // Configuring just the BPM settings. 
  //if(!error){
    //Serial.println("Sensor configured.");
  //}
  //else {
    //Serial.println("Error configuring sensor.");
    //Serial.print("Error: "); 
    //Serial.println(error); 
  //}
  // Data lags a bit behind the sensor, if you're finger is on the sensor when
  // it's being configured this delay will give some time for the data to catch
  // up. 
  delay(4000); 

}
void loop(){

    // Information from the readBpm function will be saved to our "body"
    // variable.  
    body = bioHub.readBpm();
    
    currentMillis = millis();  //get the current "time" (actually the number of milliseconds since the program started)
    if (currentMillis - startMillis >= period)  //test whether the period has elapsed
    {
      testHR = !testHR;
      fakeHR += num;
      if(count == 5){
        count = 0;
        num = -num;
      }
      count++;
      startMillis = currentMillis;  //IMPORTANT to save the start time of the current LED state.
    }
    
   
    // Serial.print("Status: ");
    // Serial.println(body.status); 
    // tone(BUZZER, 85);
    if(currentMillis - startMillis >= 250){
      Serial.print("H:");
      // testHR ? Serial.print(body.heartRate + fakeHR) : Serial.print(body.heartRate);
      Serial.print(body.heartRate + fakeHR);
      Serial.print(",C:");
      Serial.print(body.confidence);
      Serial.print(",O:");
      Serial.print(body.oxygen);
      Serial.println(); 
    }
}
