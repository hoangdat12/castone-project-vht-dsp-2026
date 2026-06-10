function W = generateTypeIIPrecoder(cfg, i1, i2, isFormatedPMI)
    if nargin < 4
        isFormatedPMI = false;
    end

    % --- 1. Extract Configuration Variables ---
    N1 = cfg.CodebookConfig.N1;
    N2 = cfg.CodebookConfig.N2;
    O1 = cfg.CodebookConfig.O1;
    O2 = cfg.CodebookConfig.O2;
    L  = cfg.CodebookConfig.NumberOfBeams;
    sbAmplitude = cfg.CodebookConfig.SubbandAmplitude; 
    NPSK = cfg.CodebookConfig.PhaseAlphabetSize;
    nLayers = cfg.CodebookConfig.numLayers;

    validateInputs(nLayers, sbAmplitude, i1, i2);

    if isFormatedPMI
        [i11, i12, i13, i14, i21, i22] = extractInputs(i1, i2);
    else
        [i11, i12, i13, i14, i21, i22] = computeInputs(L, i1, i2, sbAmplitude);
    end

    [n1, n2] = computeN1N2(L, N1, N2, i12);

    % printPythonBeamSettings(i11, n1, n2, i13, i14, i21, i22);

    [p1_li, p2_li] = mappingAmplitudesK1K2ToP1P2(i14, i22);

    phi = computePhi(i14, i21, L, NPSK);

    if nLayers == 1
        W = computePrecodingMatrix(1, L, N1, N2, O1, O2, n1, n2, p1_li, p2_li, phi, i11);
        
    elseif nLayers == 2
        W_l1 = computePrecodingMatrix(1, L, N1, N2, O1, O2, n1, n2, p1_li, p2_li, phi, i11);

        W_l2 = computePrecodingMatrix(2, L, N1, N2, O1, O2, n1, n2, p1_li, p2_li, phi, i11);

        W = (1/sqrt(2)) * [W_l1, W_l2];
        
    else
        warning("Invalid nLayers parameters! Only Rank 1 and 2 are supported.");
        W = [];
    end
end

function phi = computePhi(i14, i21, L, NPsk)
    [v, n] = size(i14); 
    
    phi = ones(v, n); 
    
    K2 = mappingLToK2(L);

    for l = 1:v
        nonZeroLogic = (i14(l, :) > 0);
        Ml = sum(nonZeroLogic);
        
        if Ml == 0, continue; end
        
        indices = find(nonZeroLogic);
        vals = i14(l, indices);
        
        [~, sortOrder] = sortrows([vals', -indices'], 'descend');
        sortedIdx = indices(sortOrder);
        
        numStrong = min(Ml, K2); 
        
        strongIndices = sortedIdx(1:numStrong);
        
        weakIndices = sortedIdx(numStrong + 1:end);

        % 4. Assign Phase Values
        for i = 1:n
            if i14(l, i) == 0
                phi(l, i) = 1; 
                
            elseif ismember(i, strongIndices)
                phi(l, i) = exp(1j * 2 * pi * i21(l, i) / NPsk);
                
            elseif ismember(i, weakIndices)
                phi(l, i) = exp(1j * 2 * pi * i21(l, i) / 4);
            end
        end
    end
end

function [m1, m2] = computeM1M2(n1, n2, q1, q2, O1, O2)
    m1 = O1 * n1 + q1;
    m2 = O2 * n2 + q2;
end

function [n1, n2] = computeN1N2(L, N1, N2, i12)
    if N2 == 1
        if N1 == 2
            n1 = [0, 1]; n2 = [0, 0]; return;
        elseif N1 == 4 && L == 4
            n1 = [0, 1, 2, 3]; n2 = [0, 0, 0, 0]; return;
        end
    end

    if N1 == 2 && N2 == 2 && L == 4
        n1 = [0, 1, 0, 1]; n2 = [0, 0, 1, 1]; return;
    end

    s = 0; 
    n1 = zeros(1, L); 
    n2 = zeros(1, L);
    
    for i = 0:L-1
        x_start_val = L-1-i;
        x_end_val = N1*N2-1-i;
        
        x_star_list = x_end_val:-1:x_start_val; 
        
        x_star = 0;
        for k = 1:length(x_star_list)
            current_x = x_star_list(k);
            if checkConditionXStart(i12, s, current_x, L - i)
                x_star = current_x;
                break; % Found the largest x*, stop searching
            end
        end
        
        e_i = getValFromCTable(x_star, L - i);
        s = s + e_i; 
        
        n_i = N1*N2 - 1 - x_star;
        
        n1(i+1) = mod(n_i, N1);
        n2(i+1) = (n_i - n1(i+1)) / N1;
    end
end

function [p1_li, p2_li] = mappingAmplitudesK1K2ToP1P2(i14, i22) 
    [numRows, numCols] = size(i14);
    
    p1_li = zeros(numRows, numCols);
    p2_li = zeros(numRows, numCols);
    
    p1_val_list = [0, sqrt(1/64), sqrt(1/32), sqrt(1/16), sqrt(1/8), sqrt(1/4), sqrt(1/2), 1];

    for l = 1:numRows
        for i = 1:numCols
            k1 = i14(l, i);
            if k1 >= 0 && k1 <= 7
                p1_li(l, i) = p1_val_list(k1 + 1);
            else
                warning('Invalid i14 value at layer %d, port %d', l, i);
            end

            k2 = i22(l, i);
            if k2 == 0
                p2_li(l, i) = sqrt(1/2); 
            elseif k2 == 1
                % k=1 maps to 1
                p2_li(l, i) = 1;
            else
                warning('Invalid i22 value at layer %d, port %d', l, i);
                p2_li(l, i) = 1; % Default fallback
            end
        end
    end
end

function K2 = mappingLToK2(L)
    if L == 2 || L == 3
        % For L=2 or L=3, K^(2) = 4 [cite: 289, 291]
        K2 = 4;
    elseif L == 4 
        % For L=4, K^(2) = 6 [cite: 293]
        K2 = 6;
    else
        % It is recommended to use error() here to stop execution on invalid input
        warning("Invalid L parameters!");
    end
end

function v = computeBeam(l, m, N1, N2, O1, O2, phaseFactor)
    if N2 == 1
        u_n2 = 1; % 1D array case
    else 
        n2 = (0:N2-1).';
        % Exp: j * 2pi * m * n2 / (O2 * N2)
        u_n2 = exp(1j * phaseFactor * pi * m * n2 / (O2 * N2));
    end
    
    n1 = (0:N1-1).';
    % Exp: j * 2pi * l * n1 / (O1 * N1)
    u_n1 = exp(1j * phaseFactor * pi * l * n1 / (O1 * N1));
  
    v = kron(u_n1, u_n2);
    v = v(:); % Ensure column vector
end

function W = computePrecodingMatrix(l, L, N1, N2, O1, O2, n1, n2, p1, p2, phi, i11)
    q1 = i11(1);
    q2 = i11(2);
    [m1, m2] = computeM1M2(n1, n2, q1, q2, O1, O2);

    p_comp = p1(l, :) .* p2(l, :); 
    sum_energy = sum(p_comp.^2); 
    norm_factor = sqrt(N1 * N2 * sum_energy); 

    sum_first_matrix = zeros(N1 * N2, 1);  % Polarization +45
    sum_second_matrix = zeros(N1 * N2, 1); % Polarization -45

    % 4. Linear Combination Loop
    for i = 0:(L-1)
        idx = i + 1; 
        
        v_lm = computeBeam(m1(idx), m2(idx), N1, N2, O1, O2, 2);

        term1 = v_lm * p1(l, idx) * p2(l, idx) * phi(l, idx);
        sum_first_matrix = sum_first_matrix + term1;

        term2 = v_lm * p1(l, idx + L) * p2(l, idx + L) * phi(l, idx + L);
        sum_second_matrix = sum_second_matrix + term2;
    end

    W = (1 / norm_factor) * [sum_first_matrix; sum_second_matrix];
end

function isValid = checkConditionXStart(i12, s, x, y)
    val = getValFromCTable(x, y);
    % Check if remaining value is large enough for the combinatorial coefficient
    isValid = (i12 - s) >= val;
end

function val = getValFromCTable(x, y)
    C = [ ...
        0   0   0   0;    % x = 0
        1   0   0   0;    % x = 1
        2   1   0   0;    % x = 2
        3   3   1   0;    % x = 3
        4   6   4   1;    % x = 4
        5  10  10   5;    % x = 5
        6  15  20  15;    % x = 6
        7  21  35  35;    % x = 7
        8  28  56  70;    % x = 8
        9  36  84 126;    % x = 9
       10  45 120 210;    % x = 10
       11  55 165 330;    % x = 11
       12  66 220 495;    % x = 12
       13  78 286 715;    % x = 13
       14  91 364 1001;   % x = 14
       15 105 455 1365    % x = 15
    ];

    % Safety check for indices
    if x < 0 || y < 1 || y > 4 || x + 1 > size(C, 1)
        val = 0; 
    else
        % Map x to row index (MATLAB is 1-based)
        val = C(x + 1, y);
    end
end

function printPythonBeamSettings(i11, n1, n2, i13, i14, i21, i22)
    num_layers = length(i13);

    % 1. Format q1q2, n1n2, strongest
    q1q2_str = sprintf('(%d, %d)', i11(1), i11(2));
    n1_str = sprintf('[%s]', strjoin(string(n1), ', '));
    n2_str = sprintf('[%s]', strjoin(string(n2), ', '));
    n1n2_str = sprintf('(%s, %s)', n1_str, n2_str);
    strongest_str = sprintf('[%s]', strjoin(string(i13), ', '));

    % Khởi tạo cell array chứa chuỗi cho k1, c, k2
    k1_layers = cell(1, num_layers);
    c_layers = cell(1, num_layers);
    k2_layers = cell(1, num_layers);

    % 2. Xử lý k1, c, k2 (Lọc bỏ giá trị tại vị trí strongest)
    for l = 1:num_layers
        % i13 là 0-based index của 3GPP, MATLAB là 1-based nên phải +1
        idx_to_remove = i13(l) + 1; 

        row_i14 = i14(l, :);
        row_i14(idx_to_remove) = []; % Xoá beam mạnh nhất
        k1_layers{l} = sprintf('[%s]', strjoin(string(row_i14), ', '));

        row_i21 = i21(l, :);
        row_i21(idx_to_remove) = [];
        c_layers{l} = sprintf('[%s]', strjoin(string(row_i21), ', '));

        row_i22 = i22(l, :);
        row_i22(idx_to_remove) = [];
        k2_layers{l} = sprintf('[%s]', strjoin(string(row_i22), ', '));
    end

    % Ghép chuỗi các layer lại với nhau
    k1_str = sprintf('(%s)', strjoin(k1_layers, ', '));
    c_str = sprintf('[(%s)]', strjoin(c_layers, ', '));   % bọc trong [] cho subbands
    k2_str = sprintf('[(%s)]', strjoin(k2_layers, ', ')); % bọc trong [] cho subbands

    % 3. In kết quả ra Command Window
    fprintf('\n=== COPY ĐOẠN NÀY VÀO FILE MAIN.PY ===\n');
    fprintf('beam_settings = {\n');
    fprintf('    ''q1q2'': %s,\n', q1q2_str);
    fprintf('    ''n1n2'': %s,\n', n1n2_str);
    fprintf('    ''strongest'': %s,\n', strongest_str);
    fprintf('    ''k1'': %s,\n', k1_str);
    fprintf('    ''k2'': %s,\n', k2_str);
    fprintf('    ''c'':  %s,\n', c_str);
    fprintf('}\n');
end

function validateInputs(nLayers, sbAmplitude, i1, i2)
% VALIDATEINPUTS Validates input structures for Type II Basic CSI Codebook.
%   Ensures the cell arrays i1 and i2 adhere to 3GPP TS 38.214 specifications
%   for "Type II Single Panel" (Basic) mode.
%
%   INPUTS:
%       nLayers     : Number of layers (Rank), v = 1 or 2.
%       sbAmplitude : Logical flag for 'subbandAmplitude'.
%       i1          : Cell array {i11, i12, i13, i14}.
%       i2          : Cell array {i21} or {i21, i22}.

    % 1. Validate i1 Structure (Wideband Information)
    % For Type II Basic, i1 must contain 4 elements:
    %   1. i1,1: Orthogonal basis set (q1, q2).
    %   2. i1,2: Orthogonal basis selector (n1, n2) - Specific to Type II Basic.
    %   3. i1,3: Strongest coefficient indicator.
    %   4. i1,4: Wideband amplitude.
    if length(i1) ~= 4
        warning("Structure i1 must contain 4 Cell elements: {i11, i12, i13, i14}.");
    else
        % For Rank 2 (v=2), reporting is required for both layers.
        % i1,3 and i1,4 must contain data for Layer 1 and Layer 2.
        if nLayers == 2
            % Check if i13 (index 3) has dimensions indicating 2 layers
            if size(i1{3}, 2) < 2 && size(i1{3}, 1) < 2
                warning("For Rank 2, i13 and i14 must contain data for both layers (matrix/vector format).");
            end
        end
    end

    % 2. Validate i2 Structure (Subband & Phase Information)
    if sbAmplitude
        % --- Case: subbandAmplitude = 'true' ---
        % i2 must contain 2 elements: {i2,1, i2,2}[cite: 117].
        %   1. i2,1: Wideband phase indicators.
        %   2. i2,2: Subband amplitude indicators.
        if length(i2) ~= 2
            warning("When Subband Amplitude is TRUE, i2 must contain 2 Cell elements: {i21, i22}.");
        end
        
        % For Rank 2, phase and subband amplitude are reported per layer.
        % Ensure the matrices have 2 rows (one for each layer).
        if nLayers == 2 && size(i2{1}, 1) < 2
             warning("For Rank 2, i21 and i22 must be matrices with 2 rows.");
        end
    else
        % --- Case: subbandAmplitude = 'false' ---
        % i2 contains only 1 element: {i2,1}.
        % i2,2 (Subband Amplitude) is NOT reported[cite: 278].
        if length(i2) ~= 1
            warning("When Subband Amplitude is FALSE, i2 must contain only 1 Cell element {i21}.");
        end
    end
end

function [i11, i12, i13, i14, i21, i22] = extractInputs(i1, i2)
    i11 = i1{1};
    i12 = i1{2};
    i13 = i1{3};
    i14 = i1{4};

    i21 = i2{1};
    i22 = i2{2};
end

% i11 = [2, 1]; i12 = [2]; i13 = [3, 1]; 
% i14 = [4, 6, 5, 0, 2, 3, 1 ; 3, 2, 4, 1, 5, 6, 0];
% i21 = [1, 3, 4, 2, 5, 7 ; 2, 0, 5, 1, 4, 6];
% i22 = [0, 1, 0, 1, 0 ; 1, 1, 0, 0, 1];
% i1 = {i11, i12, i13, i14};
% i2 = {i21, i22};
% L = 4;
function [i11, i12, i13, i14, i21, i22] = computeInputs(L, i1_cell, i2_cell, subbandAmplitude)
% COMPUTEINPUTS Reconstructs Type II CSI Codebook parameters.
%   Designed for Type II Basic (Linear Combination) which includes i1,2.
%
% INPUTS:
%   L: Number of beams.
%   i1_cell: Cell array {i11, i12, i13, i14}.
%   i2_cell: Cell array {i21} or {i21, i22}.
%   subbandAmplitude: Boolean (true/false).

    % 1. Input Processing & Defaults
    % Automatically infer subbandAmplitude if not provided
    if nargin < 4
        if length(i2_cell) >= 2
            subbandAmplitude = true;
        else
            subbandAmplitude = false;
        end
    end

    % 2. Extract Input Data
    % TYPE II BASIC Structure: {i1,1, i1,2, i1,3, i1,4}
    try
        i11 = i1_cell{1}; 
        i12 = i1_cell{2}; % Orthogonal basis selection (Specific to Type II Basic)
        i13 = i1_cell{3}; % Strongest coefficient indicator
        i14_reported = i1_cell{4}; % Reported wideband amplitudes
    catch
        error('Error extracting i1_cell. Ensure it has 4 elements {i11, i12, i13, i14} for Type II Basic.');
    end
    
    % i2_cell extraction
    if ~isempty(i2_cell)
        i21_reported = i2_cell{1}; 
    else
        error('Input i2_cell is missing data!');
    end

    % Only extract i2,2 if subbandAmplitude is TRUE and data exists
    i22_reported = [];
    if subbandAmplitude && length(i2_cell) >= 2
        i22_reported = i2_cell{2};
    end

    % 3. Initialization
    v = length(i13);              % Rank (Number of layers)
    num_ports = 2 * L;            % Total number of ports
    
    % Get K2 threshold from table (Table 5.2.2.2.3-4)
    K2 = mappingLToK2(L);

    % Pre-allocate output matrices
    i14 = zeros(v, num_ports);
    i21 = zeros(v, num_ports);
    
    % Initialize i22 to all ones.
    % This handles the default value for non-reported elements correctly.
    %: "When subbandAmplitude is set to 'false', k^(2)=1"
    i22 = ones(v, num_ports); 

    % 4. Layer-wise Reconstruction
    for l = 1:v
        % -- Step A: Strongest Coefficient (i1,3) --
        strong_idx = i13(l) + 1; 

        % -- Step B: i1,4 (Wideband Amplitude) --
        % The strongest coefficient always has amplitude index 7
        i14(l, strong_idx) = 7;
        
        rem_idx = setdiff(1:num_ports, strong_idx);
        
        % Robust assignment: Check dimensions to avoid index errors
        num_rem = length(rem_idx);
        if size(i14_reported, 2) >= num_rem
            i14(l, rem_idx) = i14_reported(l, 1:num_rem);
        else
            % Fallback for safety
            i14(l, rem_idx(1:size(i14_reported, 2))) = i14_reported(l, :);
        end

        % -- Step C: i2,1 (Wideband Phase) --
        i21(l, strong_idx) = 0; % Strongest coeff phase is 0
        
        non_zero_idx = find(i14(l, :) > 0);
        phase_pos = setdiff(non_zero_idx, strong_idx);
        
        if ~isempty(phase_pos) && ~isempty(i21_reported)
             num_phase = min(length(phase_pos), size(i21_reported, 2));
             i21(l, phase_pos(1:num_phase)) = i21_reported(l, 1:num_phase);
        end

        % Step C: Subband Amplitude Logic
        if subbandAmplitude && ~isempty(i22_reported)
            
            % 1. Strongest Beam luôn là 1 (Không nằm trong i22_reported)
            i22(l, strong_idx) = 1; 
            
            candidates = setdiff(non_zero_idx, strong_idx);
            
            if ~isempty(candidates)
                % --- BƯỚC 1: LỌC (SELECTION) ---
                % Mục đích: Tìm ra top (K2-1) thằng mạnh nhất để báo cáo.
                % Logic: Sort Amplitude Descending. Tie-break: Index Ascending.
                
                sort_mat = [i14(l, candidates)', -candidates']; 
                [~, order] = sortrows(sort_mat, 'descend');
                sorted_cand_by_strength = candidates(order); % Danh sách xếp theo độ mạnh

                M_l = length(non_zero_idx);
                num_sb = min(M_l, K2) - 1;
                
                if num_sb > 0
                    % Lấy danh sách index của những thằng được chọn
                    chosen_indices = sorted_cand_by_strength(1:num_sb);
                    
                    % --- BƯỚC 2: SẮP XẾP LẠI THEO INDEX (RE-ORDERING) --- (FIXED HERE)
                    % Bit stream i22_reported luôn map theo thứ tự index tăng dần của các port được chọn
                    target_indices = sort(chosen_indices, 'ascend');
                    
                    % --- BƯỚC 3: MAPPING ---
                    % Gán lần lượt bit báo cáo vào các index đã sắp xếp
                    len_fill = min(num_sb, size(i22_reported, 2));
                    i22(l, target_indices(1:len_fill)) = i22_reported(l, 1:len_fill);
                end
            end
        end
    end
end
