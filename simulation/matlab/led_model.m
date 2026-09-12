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
    return
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

%% ========== STAGE 1: High-Current Linear Fit ==========
function [Rs_est, Vd_est] = fitHighCurrent(current, voltage, numPoints)
    % For high currents, voltage ≈ I*Rs (dominates over exponential)
    % Linear fit: V = Rs*I + Vd
    
    N = min(length(current)/2, numPoints);
    
    % Use last N points (highest currents)
    p = polyfit(current(end-N+1:end), voltage(end-N+1:end), 1);
    Rs_est = p(1);
    Vd_est = p(2);
end

%% ========== STAGE 2: Low-Current Exponential Fit ==========
function [b_opt, c_opt] = fitLowCurrent(current, voltage, Rs, Vd, Vt, numPoints)
    % Fit: V = b * Vt * log(exp(c) * I + 1)
    % where b ≈ n and c is related to Is
    
    M = min(floor(length(current)/2), floor(numPoints));
    
    b_scale = 1.5 * Vt;  % Initial guess for n
    idx = max(1, length(current) - floor(numPoints) + 1);
    c_scale = log((exp(Vd / (1.5 * Vt)) - 1) / current(idx));
    
    % Define simple diode model for fitting
    simple_diode = @(params) b_scale * params(1) * log(exp(c_scale * params(2)) * current(1:M) + 1);
    
    % Fit parameters using least squares
    options = optimoptions('lsqnonlin', 'Display', 'off');
    params = lsqnonlin(@(x) voltage(1:M) - simple_diode(x), [1, 1], [], [], options);
    
    b_opt = params(1);
    c_opt = params(2);
end

%% ========== STAGE 3: Full Model Optimization ==========
function [Is, n, Rs, err] = fitDiodeModel(current, voltage, Vt)
    % Three-stage fitting algorithm
    
    % Stage 1: High-current linear fit
    [Rs, Vd] = fitHighCurrent(current, voltage, 1e6);
    
    % Stage 2: Low-current exponential fit
    [b_opt, c_opt] = fitLowCurrent(current, voltage, Rs, Vd, Vt, 1e6);
    
    % Stage 3: Full model optimization
    b_scale = b_opt * (1.5 * Vt);
    idx = max(1, length(current) - floor(length(current)/2) + 1);
    c_scale = exp(c_opt * log((exp(Vd / (1.5 * Vt)) - 1) / current(idx)));
    a_scale = Rs;
    
    % Full diode equation: V = b*Vt*ln(c*I + 1) + a*Rs*I
    full_diode = @(p) p(1) * b_scale * log(p(2) * c_scale * current + 1) + p(3) * a_scale * current;
    
    % Optimize all three parameters
    options = optimoptions('lsqnonlin', 'Display', 'off');
    p_opt = lsqnonlin(@(p) voltage - full_diode(p), [1, 1, 1], [0.1, 0.1, 0.1], [10, 10, 10], options);
    
    % Extract final parameters
    Rs = p_opt(3) * a_scale;
    n = p_opt(1) * b_scale / Vt;
    Is = 1 / (p_opt(2) * c_scale);
    
    % Calculate error
    err = sqrt(sum((voltage - full_diode(p_opt)).^2));
end