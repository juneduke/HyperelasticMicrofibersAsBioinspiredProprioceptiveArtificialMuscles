  int RelayPin = 5;
int motPin1 = 4;
int RelayPow = 6 ;
//int motPin2 = 3;
//int motena = 2;

void setup()
{
  delay(5000);
  Serial.begin(9600);
  pinMode(RelayPin, OUTPUT);
  pinMode(RelayPow, OUTPUT);
  pinMode(motPin1, OUTPUT);
  //pinMode(motPin2, OUTPUT);
  //pinMode(motena, OUTPUT);
  delay(200);
  
    
  digitalWrite(RelayPin, HIGH);
  digitalWrite(motPin1, HIGH);
  delay(200);
  while (!Serial);
  
  Serial.println(("Arduino is ready. Send a command to start the main process.")); //

  // Wait for incoming serial data
  while (Serial.available() == 0) {
    // Optional: add a small delay to prevent a watchdog reset on some boards
    delay(10);
  }

  // Read and discard the initial command, or store it for action
  char startCommand = Serial.read();

  //Serial.print(("Received command: "));
  //Serial.println(startCommand);
  //Serial.println(F("Starting main program loop..."));
  //Serial.println("ON_Cycle");
  //digitalWrite(RelayPin, LOW);
  //digitalWrite(motPin1, LOW);
  //delay(3000);
  //Serial.println("OFF_Cycle");
  //digitalWrite(RelayPin, HIGH); 
  //digitalWrite(motPin1, HIGH);
  delay(1000);
}

void loop()
{
  for (int i=0; i<100; i++)
  {
  // Serial.println("ON_Cycle");
  digitalWrite(RelayPin, LOW);
  digitalWrite(motPin1, LOW);
  delay(500);
  // Serial.println(i+1);
  digitalWrite(RelayPin, HIGH);
  digitalWrite(motPin1, HIGH);
  delay(1000);
  }
  delay(300000);
}
