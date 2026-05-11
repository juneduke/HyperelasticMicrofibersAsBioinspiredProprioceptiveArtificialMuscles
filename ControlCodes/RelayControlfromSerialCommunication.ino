/* * Actuator Controller: Pump and Solenoid Valve
 * Pin 5: Pump Relay (Heighten Pressure)
 * Pin 4: Valve Relay (Release Pressure)
 * Pin 6: System Power Relay
 */

const int relayPump = 4;  
const int relayValve = 5; 
const int relayPow = 6;   

void setup() {
  Serial.begin(115200);
  //Serial.setTimeout(10); // <--- Add this! Reduces wait time for parseInt()
  pinMode(relayPump, OUTPUT);
  pinMode(relayValve, OUTPUT);
  pinMode(relayPow, OUTPUT);
  
  // Initialize: All OFF (Relays are typically Active Low)
  digitalWrite(relayPump, HIGH); 
  digitalWrite(relayValve, HIGH);
  digitalWrite(relayPow, LOW); // Main power ON
}

void loop() {
  if (Serial.available() > 0) {
    // Read command: 1 = Pump, -1 = Valve, 0 = Neutral/Hold
    int command = Serial.parseInt();
    
    if (command == 1) {
      digitalWrite(relayPump, LOW);   // Pump ON
      digitalWrite(relayValve, LOW);  // Valve CLOSED
    } 
    else if (command == -1) {
      digitalWrite(relayPump, HIGH);  // Pump OFF
      digitalWrite(relayValve, HIGH);   // Valve OPEN
    } 
    else if (command == 0) {
      digitalWrite(relayPump, HIGH);  // Pump OFF
      digitalWrite(relayValve, LOW);  // Valve CLOSED
    }
  }
}
