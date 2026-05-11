# Hyperelastic Microfibers as Bioinspired Proprioceptive Artificial Muscles

This repository contains Arduino control sketches, MATLAB instrumentation scripts, and MATLAB analysis code associated with the study **"Hyperelastic Microfibers as Bioinspired Proprioceptive Artificial Muscles"**. The code was written for the experimental apparatus and analysis workflow used in the project. This README is structured for computational reproducibility review and Nature Communications-style code availability expectations.

> **Repository status:** Many of the codes are hardware- and laboratory-configuration-specific. The bundled PCA/neural-network analysis can be run from the supplied `.mat` files. Most instrumentation scripts require the original hardware, drivers, DAQ device names, channel wiring, COM-port assignments, and calibration constants.

---

## 1. Repository contents

```text
.
├── ControlCodes/                       Arduino sketches for actuation, relay, and IMU serial control
│   ├── CyclicActuation.ino
│   ├── MPUSerialCommunication(Accelerometer).ino
│   ├── PassiveCyclicStraining.ino
│   ├── RelayControl_cylclic.ino
│   ├── RelayControlfromSerialCommunication.ino
│   ├── ResponseTimeTesting .ino
│   └── StepInput.ino
├── Intrumentation/                     MATLAB acquisition/control scripts [directory name retained as provided]
│   ├── ArmModelProtocol.m
│   ├── CdS_Strain_CoupledProtocol.m
│   ├── FeedbackControlLivePlotter.m
│   ├── PressureGaugeProtocol.m
│   ├── PreviousRecordingData.mat
│   ├── RapidResponse_LoadCell.m
│   ├── RapidResponse_NoMonitor_Thorlabs.m
│   ├── Sourcmeter2450Control.m
│   └── Thorlabs_ForceGaugeSetup.m
├── PCA_NeuralNetwork/                  MATLAB PCA and neural-network analysis
│   ├── DataSet1.mat
│   ├── DataSet2.mat
│   └── PCA_NeuralNetworkAnalysis.m
├── CITATION.cff
├── LICENSE
└── README.md
```

---

## 2. Required software

### 2.1 MATLAB environment

The MATLAB scripts use the modern `serialport`, `daq`, and `visadev` interfaces. A tested submission should report the exact MATLAB release and toolbox versions used by the authors. The scripts are expected to require:

- MATLAB, recommended: R2021b or later.
- Data Acquisition Toolbox.
- Data Acquisition Toolbox Support Package for National Instruments NI-DAQmx Devices.
- Instrument Control Toolbox for `serialport` and `visadev`/VISA instrument communication.
- Curve Fitting Toolbox for `FeedbackControlLivePlotter.m`.
- Statistics and Machine Learning Toolbox for `pca` in `PCA_NeuralNetworkAnalysis.m`.
- Deep Learning Toolbox, formerly Neural Network Toolbox, for `fitnet` and Levenberg-Marquardt training in `PCA_NeuralNetworkAnalysis.m`.
- Thorlabs optical power meter MATLAB driver: `https://github.com/Tinyblack/Matlab-Driver-for-Thorlabs-power-meter`.
- Vendor VISA/USB drivers for connected instruments, including Keithley 2450 and Thorlabs instruments.


### 2.2 Arduino environment

The Arduino sketches require:

- Arduino IDE (1.8.x or 2.x).
- Arduino board package for the board used in the experiments: `arduino:avr:mega`.
- Built-in Arduino libraries: `Stepper`, `Wire`.
- External Arduino library: `elapsedMillis` for the stepper-control sketches.
- MPU-6050 or equivalent I2C IMU for `MPUSerialCommunication(Accelerometer).ino`.
- Relay module and stepper driver wiring consistent with the pin maps below.

Install the external Arduino library in the Arduino IDE Library Manager

---

## 3. Hardware and instrument configuration

These scripts assume the following laboratory hardware classes. Replace device names, COM ports, DAQ device IDs, and calibration constants with those for the local setup before running.

| Component | Used by | Configuration appearing in code |
|---|---|---|
| Arduino-compatible microcontroller | all `.ino`; MATLAB serial-control scripts | Sketch-dependent serial rate: 9600 or 115200 baud, specified in each script |
| Stepper motor and stepper driver | `CyclicActuation.ino`, `PassiveCyclicStraining.ino`, `ResponseTimeTesting .ino`, `StepInput.ino` | Pins 7/5 for one motor and 10/8 for another through `Stepper(...)`; auxiliary pins 2-10 |
| Pump/valve relay module | relay sketches; `FeedbackControlLivePlotter.m` | Active-low relay behavior assumed; pump/valve pins 4/5 and power pin 6 |
| MPU-6050 IMU | `MPUSerialCommunication(Accelerometer).ino`; `FeedbackControlLivePlotter.m` | I2C address `0x68`; serial stream `Roll,Pitch,Yaw` at 115200 baud |
| National Instruments DAQ | most instrumentation scripts | Device name hard-coded as `Dev2`; channels vary by script |
| Thorlabs power meter | Thorlabs scripts and feedback controller | Requires `ThorlabsPowerMeter` MATLAB class and vendor drivers |
| Force gauge / load cell serial interface | `RapidResponse_LoadCell.m`, `Thorlabs_ForceGaugeSetup.m` | 2400 baud, `DataBits=8`; code uses COM7 or COM29 |
| Keithley 2450 source meter | `Sourcmeter2450Control.m` | VISA address placeholder `VISAADDRESS`; SCPI 4-wire resistance logging |

### Safety note

The relay and actuation sketches control pumps, valves, and motors. Verify wiring, current limits, pneumatic pressure limits, motor travel limits, emergency stop behavior, and active-low/active-high relay logic before connecting actuators. Run initial tests with actuators disconnected or mechanically unloaded.

---

## 4. General setup before running code

1. Clone or unzip the repository.
2. Keep the directory structure unchanged so relative file loads continue to work.
3. Open MATLAB from the repository root, or add the relevant subdirectories to the MATLAB path:

```matlab
addpath('Path')
```

4. Update placeholder strings before running hardware scripts:

| Placeholder | Where | Replace with |
|---|---|---|
| `FILENAME`, `Filename`, `filename` | acquisition scripts | desired output base name |
| `DIRECTORY` | `PCA_NeuralNetwork/PCA_NeuralNetworkAnalysis.m` | absolute path to `PCA_NeuralNetwork/` |
| `DriverPath`, `DependencyPathway`, `THORLABSPATH` | Thorlabs scripts | local path to the Thorlabs MATLAB driver |
| `VISAADDRESS` | `Sourcmeter2450Control.m` | VISA resource string for Keithley 2450 |
| `COM3`, `COM5`, `COM7`, `COM14`, `COM29` | serial scripts | local COM ports from Windows Device Manager or MATLAB `serialportlist` |
| `Dev2` | DAQ scripts | local NI device name from `daqlist` |

5. Confirm available serial ports and DAQ devices:

```matlab
serialportlist("available")
daqlist
```

6. For scripts using Arduino sketches and MATLAB together, upload the Arduino sketch first, close the Arduino serial monitor, and then run the MATLAB script so MATLAB can acquire the serial port.

---

## 5. Arduino sketches

For Arduino IDE use, place each `.ino` file inside a folder with the same base name as the sketch if prompted by the IDE. With `arduino-cli`, compile and upload as follows:

```bash
arduino-cli compile --fqbn <fqbn> "ControlCodes/<sketch-folder-or-file>"
arduino-cli upload  --fqbn <fqbn> -p <serial-port> "ControlCodes/<sketch-folder-or-file>"
```

Several sketches wait at startup until a serial byte is received, to initiate the experiment at wanted periods. After uploading, open the serial monitor at the sketch baud rate and send any character, or have the corresponding MATLAB script open the serial port and write the startup command.

### 5.1 `ControlCodes/CyclicActuation.ino`

**Purpose:** Stepper-based cyclic actuation protocol.

**Dependencies:** `elapsedMillis`, `Stepper`.

**Serial:** 9600 baud. The setup routine prints `s` and waits until a serial byte is available.

**Pin map in code:**

| Function | Pin |
|---|---:|
| Motor 1 direction | 8 |
| Motor 1 stop | 9 |
| Motor 1 speed | 10 |
| Motor 2 direction | 5 |
| Motor 2 stop | 6 |
| Motor 2 speed | 7 |
| Mode switch | 2 |
| Manual direction | 3 |
| Manual step | 4 |

**Run procedure:**

1. Install `elapsedMillis`.
2. Select the Arduino board and port.
3. Upload `CyclicActuation.ino`.
4. Send one serial character at 9600 baud to exit the startup wait.
5. Set the mode switch high to run the cyclic protocol. Set the mode switch low to allow manual stepping using pins 3 and 4.

**Outputs:** No data file is written. The sketch controls motor motion only.

**Important tunable parameters:** `stepsize`, `stopt`, `interval`, `sp`, and hard-coded step counts such as `-4000` and `4000`.

### 5.2 `ControlCodes/MPUSerialCommunication(Accelerometer).ino`

**Purpose:** Read an MPU-6050-compatible IMU, apply a complementary filter, and stream roll, pitch, and yaw over serial.

**Dependencies:** `Wire`.

**Serial:** 115200 baud.

**I2C:** IMU address `0x68`.

**Run procedure:**

1. Connect the MPU IMU to the Arduino I2C pins and confirm address `0x68`.
2. Upload the sketch.
3. Open the serial monitor at 115200 baud.
4. Leave the IMU still during startup while `calibrateGyro()` averages 500 samples.
5. Confirm the stream format:

```text
roll,pitch,yaw
```

**Used by:** `Intrumentation/FeedbackControlLivePlotter.m`, which expects comma-separated roll, pitch, and yaw values.

### 5.3 `ControlCodes/PassiveCyclicStraining.ino`

**Purpose:** Passive cyclic straining using the second configured stepper motor.

**Dependencies:** `elapsedMillis`, `Stepper`.

**Serial:** 9600 baud. The setup routine prints `s` and waits until a serial byte is available.

**Run procedure:**

1. Upload the sketch.
2. Send one serial character at 9600 baud.
3. Set the mode switch high to run the passive cyclic straining sequence: approximately `-1060` steps, delay, `1066` steps, delay.
4. Set the mode switch low for manual stepping of `myStepper2`.

**Important tunable parameters:** `stopt`, `interval`, `sp`, and the hard-coded cyclic step counts.

### 5.4 `ControlCodes/RelayControl_cylclic.ino`

**Purpose:** Open-loop cyclic relay actuation.

**Serial:** 9600 baud. The sketch waits for an initial serial character before starting.

**Pin map in code:**

| Function | Pin |
|---|---:|
| Relay control | 5 |
| Motor/pump control | 4 |
| Relay power | 6 |

**Run procedure:**

1. Upload the sketch.
2. Open serial at 9600 baud and send one character.
3. The loop performs 100 active-low cycles: `LOW` for 500 ms and `HIGH` for 1000 ms, then waits 300000 ms.

**Outputs:** No data file is written.

### 5.5 `ControlCodes/RelayControlfromSerialCommunication.ino`

**Purpose:** Serial-controlled pump and valve relay controller. This is designed to pair with `FeedbackControlLivePlotter.m`.

**Serial:** 115200 baud.

**Pin map in code:**

| Function | Pin | Logic in code |
|---|---:|---|
| Pump relay | 4 | Active low |
| Valve relay | 5 | Active low |
| System power relay | 6 | `LOW` at startup |

**Serial commands:**

| Command | Pump | Valve | Intended state |
|---:|---|---|---|
| `1` | ON | CLOSED | Increase pressure / raise actuator |
| `-1` | OFF | OPEN | Release pressure / lower actuator |
| `0` | OFF | CLOSED | Hold |

**Run procedure:**

1. Upload this sketch to the actuator-control Arduino.
2. Keep the Arduino connected to the COM port configured as `controlPort` in `FeedbackControlLivePlotter.m`.
3. Run `FeedbackControlLivePlotter.m`, or manually send `1`, `0`, and `-1` over serial for bench testing.

### 5.6 `ControlCodes/ResponseTimeTesting .ino`

**Purpose:** Stepper response-time testing across a range of speeds.

**Dependencies:** `elapsedMillis`, `Stepper`.

**Serial:** 9600 baud. The setup routine prints `s` and waits until a serial byte is available.

**Run procedure:**

1. Upload the sketch.
2. Send one serial character at 9600 baud.
3. Set the mode switch high to execute the response protocol.
4. The sketch moves to a starting displacement, runs step inputs with `sp` increasing from 1500 in increments of 100, then returns to the initial position.

**Important tunable parameters:** `stepsize=250`, `interval=5000`, starting `sp=1500`, and speed increment.

### 5.7 `ControlCodes/StepInput.ino`

**Purpose:** Step-input actuation protocol using two stepper motors.

**Dependencies:** `elapsedMillis`, `Stepper`.

**Serial:** 9600 baud. The setup routine prints `s` and waits until a serial byte is available.

**Run procedure:**

1. Upload the sketch.
2. Send one serial character at 9600 baud.
3. Set the mode switch high to execute the step-input sequence.
4. The code applies increasing step amplitudes to `myStepper` and smaller pulses to `myStepper2`, to control both the pump and custom linear stages.


---

## 6. MATLAB instrumentation scripts

Run instrumentation scripts from the `Intrumentation/` directory unless otherwise stated. Before running, update file names, COM ports, DAQ device IDs, and driver paths.

### 6.1 `Intrumentation/ArmModelProtocol.m`

**Purpose:** Record a two-actuator arm-model experiment using NI DAQ voltage channels and live plotting.

**Required hardware/software:** NI DAQ device, Data Acquisition Toolbox, configured analog inputs/outputs.

**DAQ configuration:**

```matlab
d = daq("ni");
d.Rate = 2000000;
addinput(d,"Dev2",[1 3 5 6 16],"Voltage");
addoutput(d,"Dev2",[0 1],"Voltage");
write(d, [1 1]);
```

**Measured/logged variables:** `Time`, `Angle`, `VolumeBicep`, `VolumeTricep`, `Optical_Bicep`, `Optical_Tricep`.

**Run procedure:**

1. Replace `filename = 'FILENAME';` with a descriptive output base name.
2. Replace `Dev2` and channels if the DAQ configuration differs.
3. Confirm the calibration constants in `daqreadout` for local sensors.
4. Run:

```matlab
cd Intrumentation
ArmModelProtocol
```

5. Press the GUI **Stop** button to end acquisition.

**Outputs:** `.mat` workspace file and `.csv` table containing time-series data.

### 6.2 `Intrumentation/CdS_Strain_CoupledProtocol.m`

**Purpose:** Record coupled CdS optical sensor, strain, and volume data using NI DAQ and Arduino serial synchronization.

**Required hardware/software:** NI DAQ, Arduino on COM14 or updated port.

**DAQ/serial configuration in code:**

```matlab
d = daq("ni");
device2 = serialport("COM14",9600);
```

**Measured/logged variables:** `Time`, `Volume`, `Strain`, `Optical`.

**Run procedure:**

1. Upload the appropriate Arduino actuation sketch if serial triggering is used.
2. Replace `filename = 'filename';` with the desired output base name.
3. Update `COM14`, `Dev2`, channels, and calibration constants.
4. Run:

```matlab
cd Intrumentation
CdS_Strain_CoupledProtocol
```

5. Stop acquisition from the GUI.

**Outputs:** `.mat` workspace file and `.csv` table.

### 6.3 `Intrumentation/FeedbackControlLivePlotter.m`

**Purpose:** Closed-loop bang-bang control using Thorlabs optical power readings, a spline calibration, IMU feedback, and a serial-controlled pump/valve Arduino.

**Required hardware/software:** Thorlabs optical power meter, IMU Arduino running `MPUSerialCommunication(Accelerometer).ino`, actuator-control Arduino running `RelayControlfromSerialCommunication.ino`, Curve Fitting Toolbox.

**Configuration in code:**

```matlab
imuPort = "COM3";
controlPort = "COM5";
baudRate = 115200;
targetAngle = 5;
holdDuration = 5;
smoothingParam = 0.8;
thorlabsPath = "THORLABSPATH";
```

**Calibration file:** `PreviousRecordingData.mat` is included in `Intrumentation/` and contains `calX` and `calY` variables.

**Important correction before running:** The script currently calls:

```matlab
load('PreviousRecordingData.mat', 'calX', 'calY');
```

**Run procedure:**

1. Upload `MPUSerialCommunication(Accelerometer).ino` to the IMU Arduino.
2. Upload `RelayControlfromSerialCommunication.ino` to the actuator-control Arduino.
3. Update `imuPort`, `controlPort`, `thorlabsPath`, `targetAngle`, and `holdDuration`.
4. Confirm `PreviousRecordingData.mat` is in the current directory or MATLAB path.
5. Run:

```matlab
cd Intrumentation
FeedbackControlLivePlotter
```

6. Use the **EMERGENCY STOP** GUI button if needed.

**Outputs:** A session `.mat` file named like `Session_yyyy-mm-dd_HHMM.mat`, containing `dataLog_new = [Time, Power, Roll, Pitch, Yaw, PredictedAngle]`.

### 6.4 `Intrumentation/PressureGaugeProtocol.m`

**Purpose:** Record pressure-gauge-related analog measurements from NI DAQ with live plotting.

**Required hardware/software:** NI DAQ and Data Acquisition Toolbox.

**Run procedure:**

1. Replace `filename = 'Filename';`.
2. Update `Dev2`, channels, rate, and calibration constants if required.
3. Run:

```matlab
cd Intrumentation
PressureGaugeProtocol
```

4. Stop acquisition from the GUI.

**Outputs:** `.mat` workspace file and `.csv` table.

### 6.5 `Intrumentation/RapidResponse_LoadCell.m`

**Purpose:** Log force/load response from a serial load-cell or force-gauge interface.

**Required hardware/software:** Serial force gauge/load cell.

**Serial configuration in code:**

```matlab
device = serialport("COM7",2400,"DataBits",8,"Timeout",10);
```

**Run procedure:**

1. Replace `filename = 'Filename';`.
2. Update `COM7` to the local force-gauge port.
3. Confirm the serial terminator and decoding routine match the force-gauge model.
4. Run:

```matlab
cd Intrumentation
RapidResponse_LoadCell
```

**Outputs:** `.mat` workspace file and `.csv` table containing force-time data.

### 6.6 `Intrumentation/RapidResponse_NoMonitor_Thorlabs.m`

**Purpose:** Record rapid response data from DAQ channels and a Thorlabs optical power meter without the full live monitoring interface.

**Required hardware/software:** NI DAQ, Thorlabs optical power meter, Arduino or trigger device on COM14 if used.

**Configuration in code:**

```matlab
addpath("DriverPath");
d = daq("ni");
device2 = serialport("COM14",9600);
```

**Run procedure:**

1. Replace `DriverPath` with the Thorlabs MATLAB driver path.
2. Replace `filename = 'Filename';`.
3. Update `Dev2`, channels, `COM14`, and calibration constants.
4. Run:

```matlab
cd Intrumentation
RapidResponse_NoMonitor_Thorlabs
```

**Outputs:** `.mat` workspace file and `.csv` table with `Time`, `Volume`, `Strain`, and `Optical`.

### 6.7 `Intrumentation/Sourcmeter2450Control.m`

**Purpose:** Continuous 4-wire resistance logging from a Keithley 2450 source meter.

**Required hardware/software:** Keithley 2450, VISA drivers, Instrument Control Toolbox.

**Configuration in code:**

```matlab
visaAddress = 'VISAADDRESS';
sourceI     = 1e-3;
vLimit      = 2.0;
nplc        = 1;
```

**Run procedure:**

1. Identify the Keithley VISA address with MATLAB, NI MAX, or Keysight Connection Expert.
2. Replace `VISAADDRESS`.
3. Set source current, compliance voltage, and NPLC for the sample under test.
4. Run:

```matlab
cd Intrumentation
Sourcmeter2450Control
```

5. Close the plot window to stop acquisition. The script turns source output off during shutdown.

**Outputs:** `Resistance_Log_yyyymmdd_HHMMSS.csv` with `Timestamp` and `Resistance_Ohms`.

### 6.8 `Intrumentation/Thorlabs_ForceGaugeSetup.m`

**Purpose:** Simultaneous recording of volume, strain, load, and Thorlabs optical power.

**Required hardware/software:** NI DAQ, serial force gauge/load cell, Thorlabs optical power meter, Arduino/trigger device on COM14 if used.

**Configuration in code:**

```matlab
addpath("DependencyPathway");
d = daq("ni");
device  = serialport("COM29",2400,"DataBits",8,"Timeout",10);
device2 = serialport("COM14",9600);
```

**Run procedure:**

1. Replace `DependencyPathway` with the Thorlabs driver path.
2. Replace `filename = 'FILENAME';`.
3. Update `COM29`, `COM14`, `Dev2`, channels, and calibration constants.
4. Run:

```matlab
cd Intrumentation
Thorlabs_ForceGaugeSetup
```

5. Stop acquisition from the GUI.

**Outputs:** `.mat` workspace file and `.csv` table with `Time`, `Volume`, `Load`, `Strain`, and `Optical`.

---

## 7. PCA and neural-network analysis

### 7.1 Input data

The analysis uses two bundled MATLAB data files:

| File | Variables |
|---|---|
| `PCA_NeuralNetwork/DataSet1.mat` | `Time`, `Angle`, `BicepVolume`, `TricepVolume`, `BicepOptical`, `TricepOptical` |
| `PCA_NeuralNetwork/DataSet2.mat` | `Time2`, `Angle2`, `BicepVolume2`, `TricepVolume2`, `BicepOptical2`, `TricepOptical2` |

Dataset dimensions in the supplied files:

| Dataset | Samples | Predictor channels | Response |
|---|---:|---:|---|
| `DataSet1.mat` | 3001 | 4 | `Angle` |
| `DataSet2.mat` | 6602 | 4 | `Angle2` |

### 7.2 What the script does

`PCA_NeuralNetworkAnalysis.m` performs the following steps:

1. Loads `DataSet1.mat` and forms:

```matlab
X = [BicepVolume, TricepVolume, BicepOptical, TricepOptical];
Y = Angle;
```

2. Standardizes each channel using the dataset mean and standard deviation.
3. Loads `DataSet2.mat` and forms:

```matlab
X2 = [BicepVolume2, TricepVolume2, BicepOptical2, TricepOptical2];
Y2 = Angle2;
```

4. Standardizes the second dataset independently.
5. Concatenates the normalized predictors and responses.
6. Runs PCA and reports variance explained and the number of PCs required for at least 95% cumulative variance.
7. Generates PCA visualizations, including a scree plot, biplot, and 3D PC-score plot.
8. Trains a feed-forward neural network using:

```matlab
hiddenLayerSize = [40, 20];
net = fitnet(hiddenLayerSize, 'trainlm');
net.divideParam.trainRatio = 0.70;
net.divideParam.valRatio   = 0.15;
net.divideParam.testRatio  = 0.15;
net.trainParam.epochs      = 200;
net.trainParam.goal        = 1e-6;
net.trainParam.max_fail    = 6;
```

9. Reports test-set MSE and R².
10. Computes permutation feature importance on the test set.

### 7.3 Run procedure

From MATLAB:

```matlab
cd PCA_NeuralNetwork
PCA_NeuralNetworkAnalysis
```

If the script is run from outside the `PCA_NeuralNetwork/` folder, update:

```matlab
cd('DIRECTORY')
```

or replace it with a path-relative command such as:

```matlab
thisDir = fileparts(mfilename('fullpath'));
cd(thisDir)
```

---

## 8. Data and output files

### 8.1 Bundled data

- `Intrumentation/PreviousRecordingData.mat`: calibration data used by `FeedbackControlLivePlotter.m`. The supplied file contains `calX` and `calY`.
- `PCA_NeuralNetwork/DataSet1.mat`: first arm-model dataset.
- `PCA_NeuralNetwork/DataSet2.mat`: second arm-model dataset.

### 8.2 Generated outputs

Most MATLAB instrumentation scripts write both `.mat` and `.csv` files using the selected `filename` variable. If a file already exists, the scripts append a numeric suffix such as `(1)`, `(2)`, etc. Several scripts also attempt to save a temporary file with `errortempsave` appended if an error occurs.

For publication/review, retain:

- Raw `.mat` files generated directly from acquisition.
- Exported `.csv` files used for figures or statistics.
- Calibration files and scripts used to convert voltage/optical/force readings into physical units.
- Instrument metadata: device model, firmware/software version, sensor ranges, sampling rate, channel map, calibration date, and units.

---

## 9. Citation

If using this repository, cite the associated manuscript when available.


---

