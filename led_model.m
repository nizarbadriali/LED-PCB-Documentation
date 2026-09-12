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
    
    N = min(floor(length(current)/2), floor(numPoints));
    
    % Use last N points (highest currents)
    startIdx = length(current) - N + 1;
    p = polyfit(current(startIdx:end), voltage(startIdx:end), 1);
    Rs_est = p(1);
    Vd_est = p(2);
end

%% ========== STAGE 2: Low-Current Exponential Fit ==========
function [b_opt, c_opt] = fitLowCurrent(current, voltage, Rs, Vd, Vt)
    % Fit: V = b * Vt * log(exp(c) * I + 1)
    % where b ≈ n and c is related to Is
    
    M = floor(length(current) / 2);
    
    b_scale = 1.5 * Vt;  % Initial guess for n
    c_scale = log((exp(Vd / (1.5 * Vt)) - 1) / current(1) + 1e-10);
    
    % Define objective function for fitting
    objective = @(params) sum((voltage(1:M) - (params(1) * b_scale * log(params(2) * c_scale * current(1:M) + 1))).^2);
    
    % Initial guess
    x0 = [1, 1];
    
    % Use fminsearch for optimization
    options = optimset('Display', 'off', 'TolFun', 1e-6);
    params = fminsearch(objective, x0, options);
    
    b_opt = params(1);
    c_opt = params(2);
end

%% ========== STAGE 3: Full Model Optimization ==========
function [Is, n, Rs, err] = fitDiodeModel(current, voltage, Vt)
    % Three-stage fitting algorithm
    
    % Stage 1: High-current linear fit
    [Rs, Vd] = fitHighCurrent(current, voltage, 1e6);
    
    % Stage 2: Low-current exponential fit
    [b_opt, c_opt] = fitLowCurrent(current, voltage, Rs, Vd, Vt);
    
    % Stage 3: Full model optimization
    b_scale = b_opt * (1.5 * Vt);
    c_scale = exp(c_opt * log((exp(Vd / (1.5 * Vt)) - 1) / current(1) + 1e-10));
    a_scale = Rs;
    
    % Full diode equation: V = b*Vt*ln(c*I + 1) + a*Rs*I
    objective = @(p) sum((voltage - (p(1) * b_scale * log(p(2) * c_scale * current + 1) + p(3) * a_scale * current)).^2);
    
    % Initial guess
    x0 = [1, 1, 1];
    
    % Optimize using fminsearch
    options = optimset('Display', 'off', 'TolFun', 1e-8, 'MaxIter', 1000);
    p_opt = fminsearch(objective, x0, options);
    
    % Extract final parameters
    Rs = p_opt(3) * a_scale;
    n = p_opt(1) * b_scale / Vt;
    Is = 1 / (p_opt(2) * c_scale + 1e-10);
    
    % Calculate error
    V_model = p_opt(1) * b_scale * log(p_opt(2) * c_scale * current + 1) + p_opt(3) * a_scale * current;
    err = sqrt(sum((voltage - V_model).^2));
end