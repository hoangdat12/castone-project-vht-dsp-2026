function W = generateTypeIIPortSelection(cfg, nLayers, i1, i2)
% GENERATETYPEIIPORTSELECTION: Main function to generate Type II Port Selection Precoding Matrix.
%   Implements 3GPP TS 38.214 Table 5.2.2.2.4-1.
%
% INPUTS:
%   cfg     : Configuration struct (must contain nrofPorts, numberOfBeams, etc.)
%   nLayers : Transmission Rank (1 or 2).
%   i1      : Cell array {i11, i13, i14}.
%   i2      : Cell array {i21, i22}.
%
% OUTPUT:
%   W       : Precoding Matrix. Size [nPorts x nLayers].

    % 1. Extract Configuration
    nPorts = cfg.nrofPorts;
    L = cfg.numberOfBeams;            
    NPSK = cfg.phaseAlphabetSize;
    subbandAmplitude = cfg.subbandAmplitude;
    d = cfg.portSelectionSamplingSize;

    % 1. Validate inputs 
    validateCsiInputs(cfg);

    % 2. Reconstruct CSI Parameters
    % Unpack compressed indices into full matrices
    % Note: i11 is common for all layers. i13 is ignored here (~) as it was used inside computeInputs.
    [i11, ~, i14, i21, i22] = computeInputs(L, i1, i2, subbandAmplitude);

    % 3. Map Indices to Physical Values
    % Map Amplitude Indices (k1, k2) -> Physical Values (p1, p2)
    [p1_li, p2_li] = mappingAmplitudesK1K2ToP1P2(i14, i22);

    % Map Phase Indices (c) -> Physical Values (phi)
    phi = computePhi(i14, i21, L, NPSK);

    % 4. Construct Precoding Matrix W
    if nLayers == 1
        % Rank 1: W = W^(1)
        % Returns a normalized column vector [nPorts x 1]
        W = computePrecodingMatrix(1, L, p1_li, p2_li, phi, d, nPorts, i11);
        
    elseif nLayers == 2
        % Rank 2: W = 1/sqrt(2) * [W^(1), W^(2)]
        % Compute vector for Layer 1
        W_l1 = computePrecodingMatrix(1, L, p1_li, p2_li, phi, d, nPorts, i11);

        % Compute vector for Layer 2
        W_l2 = computePrecodingMatrix(2, L, p1_li, p2_li, phi, d, nPorts, i11);

        % Concatenate and Scale
        W = (1/sqrt(2)) * [W_l1, W_l2];
        
    else
        error("Invalid nLayers parameter! Only Rank 1 and 2 are supported for Type II Port Selection.");
    end
end

function validateCsiInputs(config)
% VALIDATECSIINPUTS Validates configuration for Type II Port Selection Codebook.
%   This function checks if the input structure 'config' adheres to 3GPP TS 38.214
%   specifications. If any validation fails, it throws a MATLAB error immediately.
%
%   INPUT:
%       config : Structure containing CSI parameters (nrofPorts, numberOfBeams, etc.)
%
%   THROWS:
%       MATLAB MException if validation fails.

    % Initialize error collector
    errorList = string.empty;

    % 1. Extract Data (Assign -1 if missing to force validation failure)
    if isfield(config, 'nrofPorts'), P_csirs = config.nrofPorts; else, P_csirs = -1; end
    if isfield(config, 'numberOfBeams'), L = config.numberOfBeams; else, L = -1; end
    if isfield(config, 'portSelectionSamplingSize'), d = config.portSelectionSamplingSize; else, d = -1; end
    if isfield(config, 'phaseAlphabetSize'), N_psk = config.phaseAlphabetSize; else, N_psk = -1; end
    
    % Flags to control dependent checks (to prevent cascading false errors)
    p_valid = false;
    l_valid = false;
    d_valid = false;

    % 2. Validate nrofPorts (P_csirs)
    % Rule: P_csirs must be in {4, 8, 12, 16, 24, 32} 
    valid_ports = [4, 8, 12, 16, 24, 32];
    if ~ismember(P_csirs, valid_ports)
        errorList(end+1) = sprintf("Invalid 'nrofPorts' (%d). Must be one of {%s}.", ...
            P_csirs, num2str(valid_ports));
    else
        p_valid = true;
    end

    % 3. Validate numberOfBeams (L)
    % Rule: If P=4 -> L=2; If P>4 -> L in {2, 3, 4}
    if p_valid && P_csirs == 4
        if L ~= 2
            errorList(end+1) = sprintf("For 'nrofPorts'=4, 'numberOfBeams' (L) must be 2. Current: %d.", L);
        else
            l_valid = true;
        end
    else
        % General check for L
        if ~ismember(L, [2, 3, 4])
            errorList(end+1) = sprintf("Invalid 'numberOfBeams' (L=%d). Must be in {2, 3, 4}.", L);
        else
            l_valid = true;
        end
    end

    % 4. Validate portSelectionSamplingSize (d)
    % Rule 1: d must be in {1, 2, 3, 4} 
    if ~ismember(d, [1, 2, 3, 4])
        errorList(end+1) = sprintf("Invalid 'portSelectionSamplingSize' (d=%d). Must be in {1, 2, 3, 4}.", d);
    else
        d_valid = true;
    end
    
    % Rule 2: d <= min(P/2, L) 
    % Only run this check if P, L, and d are individually valid numbers
    if p_valid && l_valid && d_valid
        limit_d = min(P_csirs / 2, L);
        if d > limit_d
            errorList(end+1) = sprintf("Constraint failed: d (%d) <= min(P/2, L) (%d).", d, limit_d);
        end
    end

    % 5. Validate phaseAlphabetSize (N_psk)
    % Rule: N_psk must be in {4, 8} 
    if ~ismember(N_psk, [4, 8])
        errorList(end+1) = sprintf("Invalid 'phaseAlphabetSize' (%d). Must be 4 or 8.", N_psk);
    end

    % 6. Validate subbandAmplitude
    % Rule: Must be 'true' or 'false' (logical) 
    if isfield(config, 'subbandAmplitude')
        if ~islogical(config.subbandAmplitude) && ~ismember(config.subbandAmplitude, [0, 1])
             errorList(end+1) = "Invalid 'subbandAmplitude'. Must be a logical value (true/false).";
        end
    else
        errorList(end+1) = "Missing field: 'subbandAmplitude'.";
    end

    % 7. Validate RI (Rank Indicator)
    % Rule: UE shall not report RI > 2 for Type II 
    if isfield(config, 'RI')
        ri = config.RI;
        if ri > 2
            errorList(end+1) = sprintf("Invalid RI (%d). Type II Port Selection supports RI <= 2.", ri);
        elseif ri < 1
            errorList(end+1) = "Invalid RI. Must be >= 1.";
        end
    end

    % 8. Validate i1_1 index (Input bounds check)
    % Formula: i1_1 in {0, 1, ..., ceil(P / 2d) - 1} [derived from cite: 29]
    if isfield(config, 'i1_1') && p_valid && d_valid
        i1_1 = config.i1_1;
        % Note: P_csirs is P in standard. The number of steps is P_csirs / 2d.
        upper_bound = ceil(P_csirs / (2 * d)) - 1;
        
        if i1_1 < 0 || i1_1 > upper_bound
            errorList(end+1) = sprintf("Index 'i1_1' (%d) out of bounds. Valid range: [0, %d] (for P=%d, d=%d).", ...
                i1_1, upper_bound, P_csirs, d);
        end
    end

    % 9. THROW ERROR IF ISSUES FOUND
    if ~isempty(errorList)
        % Combine all errors into a single message
        finalMsg = "CSI Configuration Error(s):" + newline + join(errorList, newline);
        
        % Throw the error to stop execution
        error(finalMsg);
    end
    
    % If code reaches here, inputs are valid.
end

function [i11, i13, i14, i21, i22] = computeInputs(L, i1Cell, i2Cell, subbandAmplitude)
% COMPUTEINPUTS: Reconstructs Type II CSI Codebook parameters (i1, i2).
%   Specifically designed for Type II Port Selection Codebook.
%
% INPUTS:
%   L: Number of port pairs (e.g., 2, 4, 8...). Total ports = 2*L.
%   i1Cell: Cell array containing {i11, i13, i14_reported}.
%           Note: i12 is excluded for Port Selection.
%   i2Cell: Cell array containing {i21_reported} or {i21_reported, i22_reported}.
%   subbandAmplitude: Boolean (true/false). If not provided, it is inferred from i2Cell.
%
% OUTPUTS:
%   i14: Wideband Amplitude (reconstructed full vector).
%   i21: Wideband Phase (reconstructed full vector).
%   i22: Subband Amplitude (reconstructed full vector).

    % 1. Input Processing & Default Values
    % If the user does not provide subbandAmplitude, infer it automatically.
    if nargin < 4
        % If i2Cell has 2 elements -> i22 exists -> True. Otherwise False.
        if length(i2Cell) >= 2
            subbandAmplitude = true;
        else
            subbandAmplitude = false;
        end
    end

    % 2. Data Extraction
    % Extract i1 (Wideband info)
    % Note: Assumes i1Cell structure is {i11, i13, i14}. 
    % i12 is skipped as per Port Selection requirements.
    i11 = i1Cell{1}; 
    i13 = i1Cell{2}; 
    i14_reported = i1Cell{3}; 
    
    % Extract i2 (Phase & Subband info)
    % i21 always exists
    if ~isempty(i2Cell)
        i21_reported = i2Cell{1}; 
    else
        error('Input i2Cell is missing data!');
    end

    % i22 is retrieved only if mode is TRUE and data exists
    i22_reported = [];
    if subbandAmplitude && length(i2Cell) >= 2
        i22_reported = i2Cell{2};
    end

    % 3. Matrix Initialization
    v = length(i13);              % Rank (number of layers)
    num_ports = 2 * L;            % Total number of ports
    
    % Get K2 threshold from table (Table 5.2.2.2.3-4)
    K2 = mappingLToK2(L);

    % Initialize i14, i21 to 0
    i14 = zeros(v, num_ports);
    i21 = zeros(v, num_ports);
    
    % This efficiently handles the 'false' case and the 'weakest' elements in 'true' case.
    i22 = ones(v, num_ports); 

    % 4. Layer-wise Reconstruction Loop
    for l = 1:v
        % --- STEP A: Identify Strongest Coefficient (i1,3) ---
        % Convert from 0-based index (reporting) to 1-based index (MATLAB)
        strong_idx = i13(l) + 1; 

        % --- STEP B: Reconstruct i1,4 (Wideband Amplitude) ---
        % The strongest coefficient always has amplitude index 7
        i14(l, strong_idx) = 7;
        
        % Fill the remaining values into the empty slots
        rem_idx = setdiff(1:num_ports, strong_idx);
        
        % Check dimensions to avoid index errors if input is truncated
        num_rem = length(rem_idx);
        if size(i14_reported, 2) >= num_rem
            i14(l, rem_idx) = i14_reported(l, 1:num_rem);
        else
            % Fallback if input is shorter than expected
            i14(l, rem_idx(1:size(i14_reported, 2))) = i14_reported(l, :);
        end

        % --- STEP C: Reconstruct i2,1 (Wideband Phase) ---
        % Phase of the strongest coefficient is always 0
        i21(l, strong_idx) = 0;
        
        % Find indices with non-zero amplitude (k^(1) > 0)
        non_zero_idx = find(i14(l, :) > 0);
        
        % Exclude the strongest coefficient from phase reporting
        phase_pos = setdiff(non_zero_idx, strong_idx);
        
        if ~isempty(phase_pos) && ~isempty(i21_reported)
             % Map phase values to the correct positions
             % Note: Take only the necessary amount from the reported vector
             num_phase = min(length(phase_pos), size(i21_reported, 2));
             i21(l, phase_pos(1:num_phase)) = i21_reported(l, 1:num_phase);
        end

        % --- STEP D: Reconstruct i2,2 (Subband Amplitude) ---
        % This logic runs only when subbandAmplitude = true.
        % If false, i22 remains all ones (as initialized above).
        if subbandAmplitude && ~isempty(i22_reported)
            
            % 1. Strongest coeff subband amp is always set to 1
            % (Redundant assignment for clarity, as it was initialized to 1)
            i22(l, strong_idx) = 1;
            
            % 2. Identify candidates for subband reporting
            % (All non-zero coefficients excluding the strongest one)
            candidates = setdiff(non_zero_idx, strong_idx);
            
            if ~isempty(candidates)
                % --- TIE-BREAKING RULE (Handling equal amplitudes) ---
                % Standard requirement: Prioritize min(x,y) (smaller index)
                % Solution: Sort Amplitude descending. 
                % Tie-breaker: If amplitudes are equal, sort -Index descending.
                % Result: Smaller index appears first in the sorted list.
                
                sort_mat = [i14(l, candidates)', -candidates']; 
                [~, order] = sortrows(sort_mat, 'descend');
                sorted_cand = candidates(order);

                % Calculate number of subband elements reported
                % Formula: min(Ml, K2) - 1 
                M_l = length(non_zero_idx);
                num_sb = min(M_l, K2) - 1;
                
                if num_sb > 0
                    % Map reported values to the strongest positions
                    sb_pos = sorted_cand(1:num_sb);
                    
                    % Check input bounds to prevent index errors
                    actual_sb_len = min(num_sb, size(i22_reported, 2));
                    i22(l, sb_pos(1:actual_sb_len)) = i22_reported(l, 1:actual_sb_len);
                    
                    % The remaining weakest coefficients are not reported.
                    % Their value remains 1 (due to initialization)
                end
            end
        end
    end
end

function [p1_li, p2_li] = mappingAmplitudesK1K2ToP1P2(i14, i22)
% MAPPINGAMPLITUDESK1K2TOP1P2 Maps indicator indices to physical amplitude values.
%   Performs mapping according to 3GPP TS 38.214 Tables 5.2.2.2.3-2 and 5.2.2.2.3-3.
%
% INPUTS:
%   i14: Wideband amplitude indices (0..7). Matrix [Layers x Ports].
%   i22: Subband amplitude indices (0 or 1). Matrix [Layers x Ports].
%
% OUTPUTS:
%   p1_li: Physical wideband amplitudes.
%   p2_li: Physical subband amplitudes.

    % 1. Define Mapping Tables (Lookup Tables)
    % Table 5.2.2.2.3-2: Mapping of k^(1) to p^(1)
    % Indices: 0 to 7
    p1_lookup = [0, sqrt(1/64), sqrt(1/32), sqrt(1/16), sqrt(1/8), sqrt(1/4), sqrt(1/2), 1];

    % Table 5.2.2.2.3-3: Mapping of k^(2) to p^(2)
    % Indices: 0 to 1
    % k=0 -> sqrt(1/2), k=1 -> 1
    p2_lookup = [sqrt(1/2), 1];

    % 2. Perform Vectorized Mapping
    % MATLAB allows using the matrix itself as an index.
    % Since MATLAB indices are 1-based, we add 1 to the 0-based input indices.
    
    % Map i14 to p1
    % validation: Ensure indices are within bounds (0-7)
    if any(i14(:) < 0 | i14(:) > 7)
        warning('i14 contains values out of range [0, 7]. They will be clipped.');
        i14 = max(0, min(7, i14));
    end
    p1_li = p1_lookup(i14 + 1);

    % Map i22 to p2
    % validation: Ensure indices are within bounds (0-1)
    if any(i22(:) < 0 | i22(:) > 1)
        warning('i22 contains values out of range [0, 1]. They will be treated as 1.');
    end
    % Direct mapping: k=0 maps to index 1, k=1 maps to index 2
    p2_li = p2_lookup(i22 + 1);
    
end

function phi = computePhi(i14, i21, L, NPsk)
% COMPUTEPHI: Reconstructs the Phase coefficients (phi) for Type II CSI.
%
% INPUTS:
%   i14  : Wideband Amplitude Indices (0..7). Matrix [Layers x Ports].
%   i21  : Wideband Phase Indices. Matrix [Layers x Ports].
%   L    : Number of beams (used to determine K2).
%   NPsk : Phase alphabet size (e.g., 4 or 8) for strongest coefficients.
%
% OUTPUT:
%   phi  : Complex phase coefficients.

    [v, n] = size(i14); 
    
    % Initialize phi to 1 (Phase = 0 rad) for all elements.
    % This handles the default case where Amplitude = 0.
    phi = ones(v, n); 
    
    % Get the K2 threshold based on L (Table 5.2.2.2.3-4)
    K2 = mappingLToK2(L);

    for l = 1:v
        % 1. Identify Non-Zero Coefficients
        % Find ports where amplitude index > 0
        nonZeroLogic = (i14(l, :) > 0);
        Ml = sum(nonZeroLogic);
        
        % If no non-zero elements, skip to next layer
        if Ml == 0, continue; end
        
        % Get indices and amplitude values of non-zero elements
        indices = find(nonZeroLogic);
        vals = i14(l, indices);
        
        % 2. Tie-breaking and Sorting Rule
        % 3GPP Rule: Sort by Amplitude (Descending).
        % Tie-breaker: If amplitudes are identical, prioritize the smaller index (min(x,y)).
        % Implementation: We sort [-indices] in 'descend' order.
        % Example: Index 2 and 5 have same amp. -2 > -5, so Index 2 comes first.
        [~, sortOrder] = sortrows([vals', -indices'], 'descend');
        sortedIdx = indices(sortOrder);
        
        % 3. Partition into Strong and Weak Coefficients
        % The number of strong coefficients is min(Ml, K2).
        numStrong = min(Ml, K2); 
        strongIndices = sortedIdx(1:numStrong);
        
        % The remaining coefficients are considered "Weak"
        weakIndices = sortedIdx(numStrong + 1:end);

        % 4. Compute Phase Values
        for i = 1:n
            if i14(l, i) == 0
                % Zero amplitude -> Phase is 0 (Value = 1)
                phi(l, i) = 1; 
                
            elseif ismember(i, strongIndices)
                % Strongest Coefficients:
                % Quantized using Higher Resolution (NPsk, e.g., 8PSK or QPSK)
                % Formula: exp(j * 2pi * c / N_PSK)
                phi(l, i) = exp(1j * 2 * pi * i21(l, i) / NPsk);
                
            elseif ismember(i, weakIndices)
                % Weakest Coefficients:
                % Quantized using Fixed Low Resolution (QPSK / 4)
                % Formula: exp(j * 2pi * c / 4)
                %
                phi(l, i) = exp(1j * 2 * pi * i21(l, i) / 4);
            end
        end
    end
end

function K2 = mappingLToK2(L)
% MAPPINGLTOK2: Returns the number of strongest coefficients K2.
%   Based on 3GPP TS 38.214 Table 5.2.2.2.3-4.
%
% INPUT:
%   L : Number of beams (2, 3, or 4).
%
% OUTPUT:
%   K2: The threshold for subband amplitude reporting.

    if L == 2 || L == 3
        K2 = 4;
    elseif L == 4 
        K2 = 6;
    else
        % Use error() to stop execution if L is invalid, 
        % preventing 'undefined output' errors later.
        error("Invalid L parameter! L must be 2, 3, or 4.");
    end
end

function vm = compute_vm(m, PCsiRs)
% COMPUTE_VM: Generates the basis vector v_m.
%   Based on 3GPP TS 38.214 Section 5.2.2.2.4.
%   v_m is a column vector with a 1 at index (m mod L) and 0 elsewhere.
%
% INPUTS:
%   m      : Beam index.
%   PCsiRs : Total number of CSI-RS ports.
%
% OUTPUT:
%   vm     : Column vector of size [PCsiRs/2 x 1].

    % The length of the vector is half the number of CSI-RS ports
    L_vec = PCsiRs / 2;          
    
    % Initialize column vector with zeros 
    vm = zeros(L_vec, 1);        

    % Calculate 1-based index from 0-based 'm'
    % Formula: (m mod (PCsiRs/2))
    idx = mod(m, L_vec) + 1;     
    
    % Set the specific element to 1
    vm(idx) = 1;
end

function W = computePrecodingMatrix(l, L, p1, p2, phi, d, PCsiRs, i11)
% COMPUTEPRECODINGMATRIX: Generates the Precoding Vector for a specific layer.
%   Based on 3GPP TS 38.214 Type II Port Selection Codebook.
%
% INPUTS:
%   l      : Layer index (1-based for MATLAB, used to index p1, p2, phi).
%   L      : Number of beams (L coefficients per polarization).
%   p1     : Wideband amplitude matrix [v x 2L].
%   p2     : Subband amplitude matrix [v x 2L].
%   phi    : Phase coefficient matrix [v x 2L].
%   d      : Port selection sampling size.
%   PCsiRs : Total number of CSI-RS ports.
%   i11    : Port selection index (0-based from i1 report).
%
% OUTPUT:
%   W      : Precoding vector for layer l. Size [PCsiRs x 1].

    % 1. Calculate combined Amplitude for Normalization
    % Combine wideband (p1) and subband (p2) amplitudes
    p_comp = p1(l,:) .* p2(l,:);
    
    % Calculate Euclidean norm: sqrt(sum(|coeff|^2))
    norm_factor = sqrt(sum(p_comp.^2));
    
    % Safety check to avoid division by zero
    if norm_factor == 0
        norm_factor = 1; 
    end

    % 2. Initialize sums for both polarizations
    % Each sum corresponds to half the number of antenna ports
    sum1 = zeros(PCsiRs/2, 1);
    sum2 = zeros(PCsiRs/2, 1);

    % 3. Loop through L beams to construct the vector
    for i = 0:L-1
        % MATLAB indices are 1-based
        idx = i + 1;

        % Calculate the port index 'm' based on selection index i11 and step d
        % Formula: m = i1,1 * d + i (Type II Port Selection)
        m = i11 * d + i;          
        
        % Generate the basis vector v_m (Selection vector)
        % v_m has a 1 at index (m mod P/2) + 1
        v_m = compute_vm(m, PCsiRs);

        % Accumulate weighted basis vectors
        % Polarization 1 (Indices 1 to L)
        term1 = v_m * p1(l, idx)   * p2(l, idx)   * phi(l, idx);
        sum1 = sum1 + term1;
        
        % Polarization 2 (Indices L+1 to 2L)
        term2 = v_m * p1(l, idx+L) * p2(l, idx+L) * phi(l, idx+L);
        sum2 = sum2 + term2;
    end

    % 4. Stack polarizations and Normalize
    % W = [ Pol1; Pol2 ] / Norm
    W = (1/norm_factor) * [sum1; sum2];
end
