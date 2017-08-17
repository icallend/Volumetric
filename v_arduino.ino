
/* 
 *  v_arduino.ino
 *  Reads values from an analog IR distance sensor, 
 *  converts the values to centimeters, 
 *  and writes the results to serial
 *  
 *  Ian Callender
 *  ian@iancallender.net
 *  March 2017
 *  
 */
 
void setup()
{
  Serial.begin(9600);
}

void loop()
{
  float analogIn = analogRead(4);

  float distance = 28250 / (analogIn-229.5); // equation provided by sensor manufacturer

  Serial.print(distance);
  Serial.print("\n\r");
  
  delay(100);
}
