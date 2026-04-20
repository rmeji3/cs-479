int count;
void setup(){
  Serial.begin(115200);
  count = 0;
}

void loop(){
  Serial.println(count++);
  delay(100);
}