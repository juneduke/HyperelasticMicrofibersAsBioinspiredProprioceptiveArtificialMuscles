%% Unified Data Acquisition, Control, and Verification Script
% Purpose: Real-time artificial muscle control using log-spline feedback
clear; clc; close all;

%% --- 1. CONFIGURATION & TARGETS ---
imuPort = "COM3";           % IMU Arduino Port
controlPort = "COM5";       % Actuator Controller Port (Pump/Valve)
baudRate = 115200;

% USER SETTINGS
targetAngle = 5;           % Desired angle in degrees
holdDuration = 5;            % Seconds to maintain target before releasing
smoothingParam = 0.8;       % Spline smoothing

% Path to Thorlabs Driver
thorlabsPath = "THORLABSPATH";
addpath(thorlabsPath);

%% --- 2. GENERATE CALIBRATION MODEL ---
% Load existing data to train the spline
try
    load('PreviousRecordingData.mat', 'calX', 'calY');
    
    % Clean data for spline (must be positive and finite)
    idx = (calX > 0) & isfinite(calX) & isfinite(calY);
    calX = calX(idx); calY = calY(idx);
    
    % Fit spline in log-space for better coverage of small x-values
    logX = log10(calX);
    splineFit = fit(logX, calY, 'smoothingspline', 'SmoothingParam', smoothingParam);
    fprintf('Model: Spline calibration complete.\n');
catch ME
    error('Calibration Load Error: Ensure the .mat file exists. %s', ME.message);
end

%% --- 3. INITIALIZE INSTRUMENTS ---
try
    % Thorlabs Power Meter
    meter_list = ThorlabsPowerMeter;
    test_meter = meter_list.connect(meter_list.listdevices);
    test_meter.setPowerAutoRange(1); 
    test_meter.setWaveLength(635);
    fprintf('Instrument: Thorlabs Power Meter Connected.\n');
    
    % IMU Arduino
    arduinoObj = serialport(imuPort, baudRate);
    configureTerminator(arduinoObj, "LF");
    flush(arduinoObj); 
    
    % Controller Arduino
    controlObj = serialport(controlPort, baudRate);
    configureTerminator(controlObj, "LF");
    flush(controlObj);
    fprintf('Instrument: Actuator Controller & IMU Connected.\n');
catch ME
    error('Hardware Connection Error: %s', ME.message);
end

pause(5);

%% --- 4. SETUP REAL-TIME PLOTTING ---
fig = figure('Name', 'Real-Time Control & Verification', 'Color', 'w');

subplot(2,1,1);
hPower = animatedline('Color', 'r', 'LineWidth', 1.5);
ylabel('Power (W)'); grid on; title('Optical Power Feedback');

subplot(2,1,2); hold on;
hMeasured = animatedline('Color', 'b', 'LineWidth', 1.5, 'DisplayName', 'Measured (IMU)');
hPredicted = animatedline('Color', [0.85 0.33 0.1], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'Predicted (Spline)');
yline(targetAngle, 'g--', 'LineWidth', 2, 'DisplayName', 'Target');
ylabel('Angle (Degrees)'); grid on; 
title(['Bang-Bang Control: Target ', num2str(targetAngle), ' deg']);
legend('Location', 'northeast');

stopBtn = uicontrol('Style', 'togglebutton', 'String', 'EMERGENCY STOP', ...
    'Position', [20 20 150 30], 'FontWeight', 'bold', 'ForegroundColor', 'r');

%% --- 5. MAIN ACQUISITION & CONTROL LOOP ---
sampleIdx = 1;
maxSamples = 40000;
dataLog_new = NaN(maxSamples, 6); % [Time, Power, Roll, Pitch, Yaw, PredictedAngle]
lastCommand = 0;
targetReachedTime = []; % Timer starts when this is populated
t_start = tic;

disp('Execution started. Controlling to target...');

while ishandle(fig) && get(stopBtn, 'Value') == 0
    currTime = toc(t_start);
    
    % --- Step A: Get Power & Predict Angle ---
    try
        test_meter.updateReading(0.01); 
        currentPower = test_meter.meterPowerReading;
    catch
        currentPower = NaN;
    end
    
    if ~isnan(currentPower) && currentPower > 0
        % Evaluate spline in log-space
        calcAngle = splineFit(log10(currentPower));
    else
        calcAngle = NaN;
    end
    
    % --- Step B: Control Logic & Timing ---
    if ~isnan(calcAngle)
        % 1. Determine Command
        if calcAngle < targetAngle
            currentCommand = 1;   % Raise (Pump)
        elseif calcAngle > targetAngle
            currentCommand = -1;  % Lower (Valve Release)
        else
            currentCommand = 0;   % Hold
        end
        disp(currentCommand);
        % 2. Check Timing
        if isempty(targetReachedTime)
            % If within 0.5 degrees of target, start the 5s timer
            if abs(calcAngle - targetAngle) < 0.5
                targetReachedTime = currTime;
                fprintf('Target reached at %.2fs. Holding for %ds...\n', currTime, holdDuration);
            end
        else
            % If timer has expired, break loop to finish
            if (currTime - targetReachedTime) >= holdDuration
                fprintf('Timer expired. Moving to final release.\n');
                break;
            end
        end
    else
        currentCommand = 0; % Default to hold if sensor data is lost
    end
    
    % 3. Send Serial Command to COM4 (Only on state change)

    writeline(controlObj, num2str(currentCommand));
    pause(0.01);
    %writeline(controlObj, num2str(-1));
    %pause(0.5);
    disp('written');
    
    % --- Step C: Get IMU Reading (COM3) ---
    imuData = [NaN, NaN, NaN];
    while arduinoObj.NumBytesAvailable > 0
        rawLine = readline(arduinoObj);
        % Safety check for strsplit input
        if (ischar(rawLine) || isstring(rawLine)) && strlength(rawLine) > 0
            tempParsed = str2double(strsplit(rawLine, ','));
            if numel(tempParsed) == 3 && ~any(isnan(tempParsed))
                imuData = tempParsed;
            end
        end
    end
    
    % --- Step D: Update Data Log & Plots ---
    if sampleIdx <= maxSamples
        dataLog_new(sampleIdx, :) = [currTime, currentPower, imuData, calcAngle];
        
        if ~isnan(currentPower)
            addpoints(hPower, currTime, currentPower);
        end
        if ~isnan(imuData(1))
            addpoints(hMeasured, currTime, imuData(1));
        end
        if ~isnan(calcAngle)
            addpoints(hPredicted, currTime, calcAngle);
        end
        sampleIdx = sampleIdx + 1;
    end
    
    % Scroll window every 20 seconds
    if currTime > 20
        subplot(2,1,1); xlim([currTime-20, currTime+2]);
        subplot(2,1,2); xlim([currTime-20, currTime+2]);
    end
    
    drawnow limitrate;
end

%% --- 6. FINAL RELEASE & CLEANUP ---
fprintf('Finalizing: Releasing valve and closing ports.\n');

% Mandatory release command
writeline(controlObj, "-1");
pause(0.2); % Allow time for command to process

% Cleanup objects
clear arduinoObj controlObj;
if exist('test_meter', 'var'), delete(test_meter); end

% Save session data
saveName = ['Session_', datestr(now, 'yyyy-mm-dd_HHMM'), '.mat'];
save(saveName, 'dataLog_new');
fprintf('Success. Data saved to %s\n', saveName);
