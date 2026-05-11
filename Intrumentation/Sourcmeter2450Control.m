% Keithley 2450 Continuous 4-Wire Resistance Logger & Plotter
clear; close all; clc;

% --- Configuration Parameters ---
visaAddress = 'VISAADDRESS'; 
sourceI     = 1e-3;    % [A] Current to source (e.g., 1mA)
vLimit      = 2.0;     % [V] Voltage limit (Compliance) [cite: 23]
nplc        = 1;       % Power Line Cycles (1=Balanced, 10=High Accuracy) 
windowSize  = 100;     % Points to show on the live scrolling plot

% File setup
fileName = sprintf('Resistance_Log_%s.csv', datestr(now,'yyyymmdd_HHMMSS'));
fid = fopen(fileName, 'w');
fprintf(fid, 'Timestamp,Resistance_Ohms\n');

try
    smu = visadev(visaAddress);
    smu.Timeout = 10;
    
    % --- Instrument Initialization (SCPI) ---
    write(smu, '*RST'); % Reset to defaults [cite: 4]
    
    % Configure Source: Current [cite: 21, 23]
    write(smu, 'SOUR:FUNC CURR');
    write(smu, sprintf('SOUR:CURR %g', sourceI));
    write(smu, sprintf('SOUR:CURR:VLIM %g', vLimit));
    
    % Configure Sense: Voltage [cite: 21, 27]
    write(smu, 'SENS:FUNC "VOLT"');
    write(smu, 'SENS:VOLT:RSEN ON'); % Enable 4-Wire Remote Sense 
    write(smu, sprintf('SENS:VOLT:NPLC %g', nplc));
    write(smu, 'SENS:VOLT:UNIT OHM'); % Optional: Set units to Ohms 
    
    write(smu, 'OUTP ON'); % Enable Output [cite: 26]

    % --- Real-Time Plotting Setup ---
    fig = figure('Name', 'Live Resistance Monitor', 'Color', 'w');
    ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
    hLine = animatedline('Color', [0 .45 .74], 'LineWidth', 1.5);
    xlabel('Reading Number'); ylabel('Resistance (\Omega)');
    
    fprintf('Recording started. Close the figure window to stop.\n');
    count = 0;
    
    % --- Main Loop ---
    while ishandle(fig)
        count = count + 1;
        
        % Read measurement [cite: 24]
        % "READ?" returns the current reading from the default buffer
        raw = writeread(smu, 'READ? "defbuffer1", READ');
        resVal = str2double(raw);
        
        % Record to file
        fprintf(fid, '%s,%.6f\n', datestr(now, 'HH:MM:SS.FFF'), resVal);
        
        % Update Live Plot
        addpoints(hLine, count, resVal);
        title(ax, sprintf('Current Resistance: %.4f \\Omega', resVal));
        
        % Scrolling Window Logic
        if count > windowSize
            ax.XLim = [count - windowSize, count];
        end
        
        drawnow limitrate;
    end

catch ME
    fprintf('\nProcess stopped: %s\n', ME.message);
end

% --- Safe Shutdown ---
fclose(fid);
if exist('smu', 'var')
    write(smu, 'OUTP OFF');
    clear smu;
end
fprintf('Data saved to %s\n', fileName);
