#include <Wire.h>

const int MPU_ADDR = 0x68;
float roll = 0, pitch = 0, yaw = 0;
float gyroBiasX = 0, gyroBiasY = 0, gyroBiasZ = 0;
unsigned long lastTime;
const float ALPHA = 0.98; 

void setup() {
  Serial.begin(115200); 
  Wire.begin();
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);

  calibrateGyro();
  lastTime = micros();
}

void loop() {
  unsigned long currentTime = micros();
  float dt = (currentTime - lastTime) / 1000000.0;
  lastTime = currentTime;

  int16_t ax, ay, az, gx, gy, gz;
  readMPU(ax, ay, az, gx, gy, gz);

  float rateX = (gx - gyroBiasX) / 131.0;
  float rateY = (gy - gyroBiasY) / 131.0;
  float rateZ = (gz - gyroBiasZ) / 131.0;

  float accelRoll  = atan2((float)ay, (float)az) * 180 / PI;
  float accelPitch = atan2(-(float)ax, sqrt((float)ay * ay + (float)az * az)) * 180 / PI;

  roll  = ALPHA * (roll + rateX * dt) + (1.0 - ALPHA) * accelRoll;
  pitch = ALPHA * (pitch + rateY * dt) + (1.0 - ALPHA) * accelPitch;
  yaw  += rateZ * dt;

  // Stream format: Roll,Pitch,Yaw
  Serial.print(roll); Serial.print(",");
  Serial.print(pitch); Serial.print(",");
  Serial.println(yaw);

  delay(10); // 100Hz stream
}

void calibrateGyro() {
  long sumX = 0, sumY = 0, sumZ = 0;
  for (int i = 0; i < 500; i++) {
    int16_t ax, ay, az, gx, gy, gz;
    readMPU(ax, ay, az, gx, gy, gz);
    sumX += gx; sumY += gy; sumZ += gz;
    delay(2);
  }
  gyroBiasX = sumX / 500.0;
  gyroBiasY = sumY / 500.0;
  gyroBiasZ = sumZ / 500.0;
}

void readMPU(int16_t &ax, int16_t &ay, int16_t &az, int16_t &gx, int16_t &gy, int16_t &gz) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR, 14, true);
  ax = Wire.read() << 8 | Wire.read();
  ay = Wire.read() << 8 | Wire.read();
  az = Wire.read() << 8 | Wire.read();
  Wire.read() << 8 | Wire.read(); 
  gx = Wire.read() << 8 | Wire.read();
  gy = Wire.read() << 8 | Wire.read();
  gz = Wire.read() << 8 | Wire.read();
}
