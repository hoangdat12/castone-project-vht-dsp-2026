%% =========================================================
% Test script for Type II Port Selection Precoder
% Based on 3GPP TS 38.214 Specifications
% Description: Validates the reconstruction of W for different
% configurations (Rank 1, Rank 2, L=2, L=4, Subband ON/OFF).
%% =========================================================

clc; clear;

disp("===============================================");
disp(" TEST TYPE II PORT SELECTION – ALL CASES ");
disp("===============================================");

%% =========================================================
%% CASE 1: L = 2, subbandAmplitude = false, v = 1
%% =========================================================
disp(" ");
disp("=== CASE 1: L=2 | subbandAmplitude=false | v=1 ===");

% --- 1. Configuration ---
cfg = struct();
cfg.nrofPorts = 8;
cfg.numberOfBeams = 2;          % L = 2
cfg.phaseAlphabetSize = 4;      % QPSK (N_PSK)
cfg.portSelectionSamplingSize = 1;
cfg.subbandAmplitude = false;   % Wideband only mode

nLayers = 1;

% --- 2. Input Construction (i1) ---
% i1 = {i11, i13, i14}
i11 = 0;                        % Port selection index
i13 = 1;                        % Strongest coefficient indicator (0-based)
i14 = [1 0 2];                  % Wideband amplitude indices. Size: 2L-1 = 3
i1  = {i11, i13, i14};

% --- 3. Input Construction (i2) ---
% i2 = {i21, i22}
i21 = [0 2 1];                  % Wideband phase indices
i22 = [];                       % Not used when subbandAmplitude = false
i2  = {i21, i22};

% --- 4. Generate Precoder ---
W1 = generateTypeIIPortSelection(cfg, nLayers, i1, i2);

% --- 5. Display Results ---
disp("W (Case 1):");
disp(W1);
disp("Size of W1:");
disp(size(W1)); % Expected: [nrofPorts x nLayers] -> [8 x 1]
fprintf("||W||_F = %.4f\n", norm(W1,'fro'));

%% =========================================================
%% CASE 2: L = 2, subbandAmplitude = true, v = 2
%% =========================================================
disp(" ");
disp("=== CASE 2: L=2 | subbandAmplitude=true | v=2 ===");

% --- 1. Configuration ---
cfg.subbandAmplitude = true;
nLayers = 2;

% --- 2. Input Construction (i1) ---
% i1,1 is common for both layers (defines the basis set)
i11 = 1; 

% NOTE: i1,3 must have 2 values (one per layer)
% [Layer 1 Strongest; Layer 2 Strongest]
i13 = [0; 2]; 

% NOTE: i1,4 must be a matrix: [2 rows x 3 columns] (Since 2L-1 = 3)
i14 = [3 1 2;    % Layer 1 amplitudes
       2 3 1];   % Layer 2 amplitudes
       
i1  = {i11, i13, i14};

% --- 3. Input Construction (i2) ---
% NOTE: i2,1 corresponds to reported phase elements. Must be [2 rows]
i21 = [0 1 3;    % Layer 1 phases
       2 0 1];   % Layer 2 phases

% NOTE: i2,2 (Subband) also requires 2 rows.
% Columns depend on the number of reported subband coefficients.
i22 = [1 0;      % Layer 1 subband indicators
       0 1];     % Layer 2 subband indicators
       
i2  = {i21, i22};

% --- 4. Generate Precoder ---
W2 = generateTypeIIPortSelection(cfg, nLayers, i1, i2);

% --- 5. Display Results ---
disp("Size of W2:"); 
disp(size(W2)); % Expected: [nrofPorts x nLayers] -> [8 x 2]
disp("Precoder Matrix W2:");
disp(W2);

%% =========================================================
%% CASE 3: L = 4, subbandAmplitude = true, v = 2
%% =========================================================
disp(" ");
disp("=== CASE 3: L=4 | subbandAmplitude=true | v=2 ===");

% --- 1. Configuration ---
cfg = struct();
cfg.nrofPorts = 16;
cfg.numberOfBeams = 4;          % L = 4
cfg.phaseAlphabetSize = 4;
cfg.portSelectionSamplingSize = 1;
cfg.subbandAmplitude = true;

nLayers = 2;

% --- 2. Input Construction (i1) ---
i11 = 2;

% NOTE: Strongest coefficients for 2 layers
i13 = [3; 0]; 

% NOTE: i1,4 must be a matrix: [2 rows x 7 columns] (Since 2L-1 = 7)
i14 = [3 2 1 0 1 2 0;   % Layer 1
       1 4 2 1 0 3 1];  % Layer 2
       
i1  = {i11, i13, i14};

% --- 3. Input Construction (i2) ---
% NOTE: Matrix with 2 rows (Number of columns depends on reported elements)
i21 = [0 1 2 3 1 0 2;   % Layer 1
       3 2 1 0 2 1 3];  % Layer 2

% NOTE: Matrix with 2 rows for subband indicators
i22 = [1 0 1;   % Layer 1
       0 1 1];  % Layer 2

i2  = {i21, i22};

% --- 4. Generate Precoder ---
W3 = generateTypeIIPortSelection(cfg, nLayers, i1, i2);

% --- 5. Display Results ---
disp("W (Case 3):");
disp(W3);
disp("Size of W3:");
disp(size(W3)); % Expected: [16 x 2]
fprintf("||W||_F = %.4f\n", norm(W3,'fro'));

%% =========================================================
disp(" ");
disp("===============================================");
disp(" ALL TEST CASES FINISHED SUCCESSFULLY ");
disp("===============================================");