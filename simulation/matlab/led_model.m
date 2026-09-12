clear all; close all; clc;

%% Setup
fprintf('\n');
fprintf('╔══════════════════════════════════════╗\n');
fprintf('║   LED SPICE Model Fitter (MATLAB)    ║\n');
fprintf('║   Based on Ted Yapo''s LED Modeling   ║\n');
fprintf('╚══════════════════════════════════════╝\n\n');

% Constants
Vt = 26e-3;  % Thermal voltage at room temperature (26 mV)

% Get list of .dat files in workdir folder
dataFiles = dir('workdir/*.dat');

if isempty(dataFiles)
    fprintf('\033[91m✗ No data files found in workdir/ folder\033[0m\n');
    return;
end

fprintf('\033[92m✓ Found %d data file(s)\033[0m\n\n', length(dataFiles));

%% Process each data file
for fileIdx = 1:length(dataFiles)
    filename = fullfile(dataFiles(fileIdx).folder, dataFiles(fileIdx).name);
    fprintf('\033[94mProcessing:\033[0m %s\n', filename);
    
    try
        % Load data from file
        data = readmatrix(filename);
        
        if size(data, 2) ~= 2
            fprintf('\033[91m✗ Error: File must have exactly 2 columns (current, voltage)\033[0m\n\n');
            continue;
        end
        
        current = data(:, 1);  % Column 1: current (Amps)
        voltage = data(:, 2);  % Column 2: voltage (Volts)
        
        % Ensure column vectors
        current = current(:);
        voltage = voltage(:);
        
        fprintf('  Data points: %d\n', length(current));
        fprintf('  Current range: %.3e to %.3e A\n', min(current), max(current));
        fprintf('  Voltage range: %.3f to %.3f V\n', min(voltage), max(voltage));
        
        % Fit the diode model
        [Is, n, Rs, err] = fitDiodeModel(current, voltage, Vt);
        
        % Extract model name from filename
        [~, modelName, ~] = fileparts(filename);
        modelName = strrep(modelName, ' ', '_');
        
        fprintf('\n\033[92m✓ Fit successful!\033[0m\n');
        fprintf('  Fit error: %.6e\n\n', err);
        
        % Display SPICE model
        fprintf('\033[96mSPICE Model:\033[0m\n');
        fprintf('.MODEL %s D(Is=%.6e,\n', modelName, Is);
        fprintf('+              n=%.6e,\n', n);
        fprintf('+              Rs=%.6e)\n\n', Rs);
        
    catch ME
        fprintf('\033[91m✗ Error processing file: %s\033[0m\n\n', ME.message);
        continue;
    end
end

fprintf('Done!\n\n');


%% ========== LOCAL FUNCTIONS (MUST BE AT VERY BOTTOM) ==========

function [Rs_est, Vd_est] = fitHighCurrent(current, voltage, numPoints)
    N = min(floor(length(current)/2), floor(numPoints));
    startIdx = length(current) - N + 1;
    p = polyfit(current(startIdx:end), voltage(startIdx:end), 1);
    Rs_est = max(p(1), 1e-3); % Ensure non-negative series resistance
    Vd_est = max(p(2), 0.1);  % Ensure positive diode knee voltage
end

function [b_opt, c_opt] = fitLowCurrent(current, voltage, Rs, Vd, Vt)
    M = floor(length(current) / 2);
    
    b_scale = 1.5 * Vt;
    c_scale = max((exp(Vd / (1.5 * Vt)) - 1) / max(current(1), 1e-12), 1e-3);
    
    % Objective function
    objective = @(params) sum((voltage(1:M) - (params(1) * b_scale * log(abs(params(2)) * c_scale * current(1:M) + 1))).^2);
    
    x0 = [1, 1];
    options = optimset('Display', 'off', 'TolFun', 1e-6);
    params = fminsearch(objective, x0, options);
    
    b_opt = params(1);
    c_opt = params(2);
end

function [Is, n, Rs, err] = fitDiodeModel(current, voltage, Vt)
    % Stage 1: High-current linear fit
    [Rs_init, Vd] = fitHighCurrent(current, voltage, 1e6);
    
    % Stage 2: Low-current exponential fit
    [b_opt, c_opt] = fitLowCurrent(current, voltage, Rs_init, Vd, Vt);
    
    % Stage 3: Full model optimization
    b_scale = max(b_opt * (1.5 * Vt), 1e-3);
    c_scale = max(c_opt * (exp(Vd / (1.5 * Vt)) - 1) / max(current(1), 1e-12), 1e-3);
    a_scale = Rs_init;
    
    objective = @(p) sum((voltage - (p(1) * b_scale * log(abs(p(2)) * c_scale * current + 1) + p(3) * a_scale * current)).^2);
    
    x0 = [1, 1, 1];
    options = optimset('Display', 'off', 'TolFun', 1e-8, 'MaxIter', 2000);
    p_opt = fminsearch(objective, x0, options);
    
    % Extract final parameters
    Rs = max(p_opt(3) * a_scale, 1e-4);
    n = max(p_opt(1) * b_scale / Vt, 0.5);
    Is = max(1 / (abs(p_opt(2)) * c_scale + 1e-15), 1e-18);
    
    % Calculate RMS error
    V_model = p_opt(1) * b_scale * log(abs(p_opt(2)) * c_scale * current + 1) + p_opt(3) * a_scale * current;
    err = sqrt(mean((voltage - V_model).^2));
end