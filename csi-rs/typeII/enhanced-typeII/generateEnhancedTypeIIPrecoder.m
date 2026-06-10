function W = generateEnhancedTypeIIPrecoder(cfg, nLayers, i1, i2)
    paramCombination = cfg.CodeBookConfig.ParamCombination;
    R = cfg.CodeBookConfig.NumberOfPMISubbandsPerCQISubband;
    N1 = cfg.CodeBookConfig.N1;
    N2 = cfg.CodeBookConfig.N2;
    O1 = cfg.CodeBookConfig.O1;
    O2 = cfg.CodeBookConfig.O2;

    bwpStart = cfg.CarrierConfig.NStartGrid;
    bwpSize = cfg.CarrierConfig.NSizeGrid;

    subbandSize = cfg.CSIReportConfig.SubbandSize;

    % Compute the number of subband
    numSubbands = ceil(bwpSize / subbandSize);

    % Compute N3 = Total Precoding Matrices
    N3 = computeN3(R, numSubbands, bwpStart, bwpSize, subbandSize);

    % From table L, N1, N2, i12. Get parameters L, Pv, Beta
    [L, Pv, ~] = gettingParamsFromParamCombination(paramCombination, nLayers);

    % Compute Mv = Number of Frequency Basis Vectors value
    Mv = Pv * N3/R;

    % Theory threadhold
    % K0 = Beta * 2*L * Mv;

    % Format Input
    [i11, i12, i15, i16, ~, ~, i23, i24, i25] = computeInputs(i1, i2, nLayers, N3, L, Mv);

    % Compute n1, n2 values from i12 values
    [n1, n2] = computeN1N2(L, N1, N2, i12);

    % Compute M_initial = The starting index of the Sliding Window.
    MInitial = comptuteMInitial(N3, Mv, i15);

    % Compute n_f_3l (frequency domain basis indices for each l layers)
    n_f_3l = ComputeNF3LFromI16(i16, N3, Mv, MInitial);

    [p_1_l, p_2_l] = computeP1lP2l(i23, i24);

    phi_lif = computePhaseCoefficient(i25);

    % Assumme t = 1
    t = 1;

    if nLayers == 1
        W_l1 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 1);
        W = W_l1;
    elseif nLayers == 2
        W_l1 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 1);
        W_l2 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 2);
        W = (1/sqrt(2)) * [W_l1, W_l2];
    elseif nLayers == 3
        W_l1 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 1);
        W_l2 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 2);
        W_l3 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 3);
        W = (1/sqrt(3)) * [W_l1, W_l2, W_l3];
    elseif nLayers == 4
        W_l1 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 1);
        W_l2 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 2);
        W_l3 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 3);       
        W_l4 = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
                                      n1, n2, n_f_3l, p_1_l, p_2_l, phi_lif, i11, ...
                                      t, 4);                                                     
        W = (1/sqrt(4)) * [W_l1, W_l2, W_l3, W_l4];
    else
        warning("Invalid RI values!");
    end
end

function N3 = computeN3(R, numSubbands, nBWPStart, nBWPSize, subbandSize)
    if R == 1
        % When R = 1: One precoding matrix is indicated for each subband
        N3 = numSubbands;
        
    elseif R == 2
        % When R = 2: The calculation depends on the first and last 
        N3 = 0;
        halfSB = subbandSize / 2;
        
        % --- Processing the First Subband ---
        % Calculate the offset of the BWP start relative to the subband grid.
        % Formula based on 3GPP TS 38.214
        startOffset = mod(nBWPStart, subbandSize);
        
        if startOffset >= halfSB
            % If the BWP starts in the second half of the subband grid:
            % Only 1 matrix is reported (corresponding to the remaining PRBs)
            N3 = N3 + 1;
        else
            % If the BWP starts in the first half:
            % 2 matrices are reported (one for the first part, one for the second)
            N3 = N3 + 2;
        end
        
        % --- Processing Middle Subbands ---
        % Subbands that are neither the first nor the last contribute 2 matrices each
        if numSubbands > 2
            N3 = N3 + (numSubbands - 2) * 2;
        end
        
        % --- Processing the Last Subband ---
        % Only applicable if there is more than 1 subband.
        if numSubbands > 1
            % Determine the end position of the BWP.
            % Formula: 1 + (Start + Size - 1) mod SubbandSize
            % (Start + Size - 1) is the index of the last PRB.
            lastPRBIndex = nBWPStart + nBWPSize - 1;
            
            % Note: Adding 1 as per the standard formula logic for counting.
            endPosMod = mod(1 + lastPRBIndex, subbandSize);
            
            % Handle the case where modulo is 0 (perfect alignment means full size)
            if endPosMod == 0
                endPosMod = subbandSize; 
            end
            
            if endPosMod <= halfSB
                % If the BWP ends within the first half of the subband:
                % Only 1 matrix is reported
                N3 = N3 + 1;
            else
                % If the BWP extends into the second half of the subband:
                % 2 matrices are reported
                N3 = N3 + 2;
            end
        end
        
    else
        error('Invalid R value. R must be 1 or 2.');
    end
end

function MInitial = comptuteMInitial(N3, Mv, i15)
    if N3 <= 19
        MInitial = 0;
    else
        if i15 == 0
            MInitial = 0;
        else 
            MInitial = i15 - 2*Mv;
        end
    end
end

function [i11, i12, i15, i16, i17, i18, i23, i24, i25] = computeInputs(i1, i2, nLayers, N3, L, Mv)
    i11 = i1{1};
    i12 = i1{2};
    
    if N3 <= 19
        i15 = 0; 
        i16Reported = i1{3};
        i17Reported = i1{4};
        i18Reported = i1{5};
    else
        i15 = i1{3};
        i16Reported = i1{4};
        i17Reported = i1{5};
        i18Reported = i1{6};
    end

    if ~iscell(i16Reported), i16Reported = num2cell(i16Reported, 2); end
    if ~iscell(i17Reported), i17Reported = num2cell(i17Reported, 2); end
    if ~iscell(i18Reported), i18Reported = num2cell(i18Reported, 2); end

    i16 = i16Reported;
    i17 = i17Reported;
    i18 = i18Reported;

    i23Reported = i2{1};      % Wideband Amp: Chỉ báo 1 giá trị/layer (cho pol yếu)
    i24Reported = i2{2};      % Subband Amp: Stream các giá trị khác 0 (trừ strongest)
    i25Reported = i2{3};      % Phase: Stream các giá trị khác 0 (trừ strongest)
    
    if ~iscell(i23Reported), i23Reported = num2cell(i23Reported, 2); end
    if ~iscell(i24Reported), i24Reported = num2cell(i24Reported, 2); end
    if ~iscell(i25Reported), i25Reported = num2cell(i25Reported, 2); end
    
    i24 = zeros(nLayers, 2*L, Mv);
    i25 = zeros(nLayers, 2*L, Mv);
    i23 = zeros(nLayers, 2); % [Layer, 2 Polarizations] - Cần khôi phục từ 1 giá trị
    
    bitmapLength = length(i17Reported{1});
    if bitmapLength ~= 2*L*Mv
        warning('Bitmap length (%d) does not match 2*L*Mv (%d)! Check configurations.', bitmapLength, 2*L*Mv);
    end
    
    for l = 1:nLayers
        bitmap_l = i17Reported{l};       
        i18_val = i18Reported{l};        
        vals_24 = i24Reported{l};        
        vals_25 = i25Reported{l};
        val_23_reported = i23Reported{l}; 

        strongest_linear_idx = 0; % Index chạy từ 1 đến 2*L*Mv
        
        if nLayers == 1
            target_nz_count = i18_val + 1;
            current_nz_count = 0;
            for k = 1:bitmapLength
                if bitmap_l(k) == 1
                    current_nz_count = current_nz_count + 1;
                    if current_nz_count == target_nz_count
                        strongest_linear_idx = k;
                        break; 
                    end
                end
            end
        else
            strongest_linear_idx = i18_val + 1; 
        end
        
        strongest_spatial_idx = mod(strongest_linear_idx - 1, 2*L);
        
        strongest_pol = floor(strongest_spatial_idx / L); 
        
        if strongest_pol == 0
            i23(l, 1) = 15;              % Pol 1 (chứa Strongest) -> Tự động Max
            i23(l, 2) = val_23_reported; % Pol 2 -> Lấy giá trị báo cáo
        else
            i23(l, 1) = val_23_reported; % Pol 1 -> Lấy giá trị báo cáo
            i23(l, 2) = 15;              % Pol 2 (chứa Strongest) -> Tự động Max
        end

        stream_count = 1; 
        
        for idx = 1:bitmapLength
            f_idx = floor((idx - 1) / (2*L)) + 1;  % Frequency index (1...Mv)
            i_idx = mod(idx - 1, 2*L) + 1;         % Beam index (1...2L)

            if bitmap_l(idx) == 1
                if idx == strongest_linear_idx
                    i24(l, i_idx, f_idx) = 7; % Amplitude = 1 (index 7)
                    i25(l, i_idx, f_idx) = 0; % Phase = 0
                else
                    if stream_count <= length(vals_24)
                        i24(l, i_idx, f_idx) = vals_24(stream_count);
                        i25(l, i_idx, f_idx) = vals_25(stream_count);
                        stream_count = stream_count + 1;
                    else
                        i24(l, i_idx, f_idx) = 0; 
                        i25(l, i_idx, f_idx) = 0;
                    end
                end
            else
                % Bit = 0 -> Zero coefficient
                i24(l, i_idx, f_idx) = 0; % Amplitude = 0
                i25(l, i_idx, f_idx) = 0; % Phase = 0 (thực tế không quan trọng)
            end
        end
    end
end

function [L, Pv, Beta] = gettingParamsFromParamCombination(paramCombination, nLayers)
    % Validate Input
    if ~isscalar(paramCombination) || paramCombination < 1 || paramCombination > 8
        error('paramCombination phải là số nguyên từ 1 đến 8.');
    end
    
    if ~isscalar(nLayers) || nLayers < 1 || nLayers > 4
        error('nLayers (Rank) phải là số nguyên từ 1 đến 4.');
    end

    % 2. Table 5.2.2.2.5-1 
    % Column L
    L_table = [2; 2; 4; 4; 4; 4; 6; 6];
    
    % Column Beta
    Beta_table = [1/4; 1/2; 1/4; 1/2; 3/4; 1/2; 1/2; 3/4];
    
    % Column pv with v = {1, 2}
    Pv_layers12 = [1/4; 1/4; 1/4; 1/4; 1/4; 1/2; 1/4; 1/4];
    
    % Column pv with v = {3, 4}
    Pv_layers34 = [1/8; 1/8; 1/8; 1/8; 1/4; 1/4; NaN; NaN];

    % Extract L and Beta 
    L = L_table(paramCombination);
    Beta = Beta_table(paramCombination);

    % Extract Pv based on nLayers value.
    if nLayers <= 2
        Pv = Pv_layers12(paramCombination);
    else
        Pv = Pv_layers34(paramCombination);
        
        if isnan(Pv)
            error('Cấu hình paramCombination = %d không hỗ trợ cho nLayers = %d (Rank > 2).', ...
                  paramCombination, nLayers);
        end
    end
end

function [m1, m2] = computeM1M2(n1, n2, q1, q2, O1, O2)
    m1 = O1 * n1 + q1;
    m2 = O2 * n2 + q2;
end

function [n1, n2] = computeN1N2(L, N1, N2, i12)
    if N2 == 1
        % Case: (N1,N2)=(2,1) -> i1,2 not reported 
        if N1 == 2
            n1 = [0, 1]; n2 = [0, 0]; return;
        % Case: (N1,N2)=(4,1) and L=4 -> i1,2 not reported
        elseif N1 == 4 && L == 4
            n1 = [0, 1, 2, 3]; n2 = [0, 0, 0, 0]; return;
        end
    end

    % Case: (N1,N2)=(2,2) and L=4 -> i1,2 not reported
    if N1 == 2 && N2 == 2 && L == 4
        n1 = [0, 1, 0, 1]; n2 = [0, 0, 1, 1]; return;
    end

    % --- 2. Combinatorial Algorithm  ---
    s = 0; 
    n1 = zeros(1, L); 
    n2 = zeros(1, L);
    
    % Loop for i = 0 to L-1 
    for i = 0:L-1
        % Determine range for x* 
        x_start_val = L-1-i;
        x_end_val = N1*N2-1-i;
        
        % Search for largest x* in descending order
        x_star_list = x_end_val:-1:x_start_val; 
        
        x_star = 0;
        for k = 1:length(x_star_list)
            current_x = x_star_list(k);
            % Check condition: i12 - s >= C(x*, L-i) 
            if checkConditionXStart(i12, s, current_x, L - i)
                x_star = current_x;
                break; % Found the largest x*, stop searching
            end
        end
        
        % Update s: s_i = s_{i-1} + C(x*, L-i) 
        e_i = getValFromCTable(x_star, L - i);
        s = s + e_i; 
        
        % Calculate n^(i) 
        n_i = N1*N2 - 1 - x_star;
        
        % Calculate n1^(i) and n2^(i) 
        n1(i+1) = mod(n_i, N1);
        n2(i+1) = (n_i - n1(i+1)) / N1;
    end
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

function n_f_3l = ComputeNF3LFromI16(i16, N3, Mv, MInitial)
    if iscell(i16)
        i16 = cell2mat(i16); 
    end
    
    [nRows, ~] = size(i16);
    % Initialize with Mv columns. n3,l^(0) is always 0 for all layers.
    n_f_3l = zeros(nRows, Mv); 

    for l = 1:nRows
        S_value = 0; % Initialize s_0 = 0 for each layer

        for f = 1:Mv-1
            % Find the largest x* that satisfies the combinatorial condition
            x_star = findValidXStar(N3, Mv, f, i16(l), S_value);
            
            % Update the cumulative sum S_value
            ef = computeCxy(x_star, Mv - f);
            S_value = S_value + ef;
            
            % Calculate the basis index n3,l^(f)
            if N3 <= 19
                % Mapping for smaller N3 values
                n_f_3l(l, f + 1) = N3 - 1 - x_star;
            else
                % Sliding window mapping with MInitial for N3 > 19
                n_f_l_temp = 2*Mv - 1 - x_star;
                
                if n_f_l_temp <= MInitial + 2*Mv - 1
                    % Index is within the non-wrapped part of the window
                    n_f_3l(l, f + 1) = n_f_l_temp;
                else
                    % Index wraps around the N3 boundary
                    n_f_3l(l, f + 1) = n_f_l_temp + (N3 - 2*Mv);
                end
            end
        end
    end

    function x_star = findValidXStar(N3, Mv, f, i16l, S_value)
        % XÁC ĐỊNH GIỚI HẠN TÌM KIẾM DỰA TRÊN N3
        if N3 <= 19
            search_limit = N3;
        else
            search_limit = 2 * Mv; % Khi N3 > 19, dùng cửa sổ 2*Mv
        end
        
        % Search range for x* % Logic: x* thuộc {Mv-1-f, ..., search_limit-1-f}
        % áp dụng linh hoạt cho cả 2 trường hợp
        valid_range = (search_limit - 1 - f) : -1 : (Mv - 1 - f);
        
        x_star = valid_range(end); % Default value (phòng ngừa)
        
        for v = valid_range
            Cxy_val = computeCxy(v, Mv - f);
            % Find the LARGEST x* that satisfies the condition 
            if (i16l - S_value) >= Cxy_val
                x_star = v;
                return; % Exit as soon as the largest value is found
            end
        end
    end
end

function val = computeCxy(x, y)
    % Combinatorial coefficients C(x,y) from Table 5.2.2.2.5-4
    if x < 0 || x > 18 || y < 1 || y > 9
        val = 0; % Return 0 if out of table bounds or y > x
        return;
    end

    tableData = [
        0, 0, 0, 0, 0, 0, 0, 0, 0;  % x=0
        1, 0, 0, 0, 0, 0, 0, 0, 0;  % x=1
        2, 1, 0, 0, 0, 0, 0, 0, 0;  % x=2
        3, 3, 1, 0, 0, 0, 0, 0, 0;  % x=3
        4, 6, 4, 1, 0, 0, 0, 0, 0;  % x=4
        5, 10, 10, 5, 1, 0, 0, 0, 0;  % x=5
        6, 15, 20, 15, 6, 1, 0, 0, 0;  % x=6
        7, 21, 35, 35, 21, 7, 1, 0, 0;  % x=7
        8, 28, 56, 70, 56, 28, 8, 1, 0;  % x=8
        9, 36, 84, 126, 126, 84, 36, 9, 1;  % x=9
        10, 45, 120, 210, 252, 210, 120, 45, 10;  % x=10
        11, 55, 165, 330, 462, 462, 330, 165, 55;  % x=11
        12, 66, 220, 495, 792, 924, 792, 495, 220;  % x=12
        13, 78, 286, 715, 1287, 1716, 1716, 1287, 715;  % x=13
        14, 91, 364, 1001, 2002, 3003, 3432, 3003, 2002;  % x=14
        15, 105, 455, 1365, 3003, 5005, 6435, 6435, 5005;  % x=15
        16, 120, 560, 1820, 4368, 8008, 11440, 12870, 11440;  % x=16
        17, 136, 680, 2380, 6188, 12376, 19448, 24310, 24310;  % x=17
        18, 153, 816, 3060, 8568, 18564, 31824, 43758, 48620   % x=18
    ];

    val = tableData(x + 1, y);
end

% function Knz = calculateKnz(i17)
%     numLayers = size(i23, 1);
%     Knz_per_layer = zeros(numLayers, 1);
%     for l = 1:numLayers
%         Knz_per_layer(l) = sum(i17{l} == 1);
%     end
% end

function [p_1_l, p_2_l] = computeP1lP2l(i23, i24)
    function p_1_lp = mappingK1lpToP1lp(i23_input)
        % Note: k starts from 0, so MATLAB index = k + 1
        map_values = [
            NaN;              % k=0: Reserved
            1/sqrt(128);      % k=1
            (1/8192)^(1/4);   % k=2
            1/8;              % k=3
            (1/2048)^(1/4);   % k=4
            1/(2*sqrt(8));    % k=5
            (1/512)^(1/4);    % k=6
            1/4;              % k=7
            (1/128)^(1/4);    % k=8
            1/sqrt(8);        % k=9
            (1/32)^(1/4);     % k=10
            1/2;              % k=11
            (1/8)^(1/4);      % k=12
            1/sqrt(2);        % k=13
            (1/2)^(1/4);      % k=14
            1                 % k=15
        ];

        p_1_lp = map_values(i23_input + 1);
        
        % Ensure output has same shape as input (Layer x 2)
        p_1_lp = reshape(p_1_lp, size(i23_input));
    end

    function p_2_lif = mappingK2lifToP2Lif(i24_input)
        % Note: k starts from 0, so MATLAB index = k + 1
        map_values = [
            1/(8*sqrt(2));    % k=0
            1/8;              % k=1
            1/(4*sqrt(2));    % k=2
            1/4;              % k=3
            1/(2*sqrt(2));    % k=4
            1/2;              % k=5
            1/sqrt(2);        % k=6
            1                 % k=7
        ];

        p_2_lif = map_values(i24_input + 1);

        % Ensure output has same shape as input [Layer, 2L, Mv]
        p_2_lif = reshape(p_2_lif, size(i24_input));
    end

    % --- Main Execution ---
    p_1_l = mappingK1lpToP1lp(i23);
    p_2_l = mappingK2lifToP2Lif(i24);
end

function phi_lif = computePhaseCoefficient(i25)
    phi_lif = exp(1j * 2 * pi * i25 / 16);

end

function y_tlf = computeRotatedDFTPhase(n_f_3l, N3, t)
    y_tlf = exp(1j * 2*pi * t .* n_f_3l / N3);
end

function gama_tl = computeGamatl(L, Mv, p1lp, ytlf, l, p2lif, philif)
    y_vec = ytlf(l, :); 

    p2_mat = reshape(p2lif(l, :, :), 2*L, Mv);
    phi_mat = reshape(philif(l, :, :), 2*L, Mv);

    p2_mat(isnan(p2_mat)) = 0;   
    phi_mat(isnan(phi_mat)) = 0; 
    y_vec(isnan(y_vec)) = 0;     

    p1_vals = p1lp(l, :);        
    p1_vals(isnan(p1_vals)) = 0; % Xử lý NaN cho p1 nếu có

    p1_vec = [repmat(p1_vals(1), L, 1);
              repmat(p1_vals(2), L, 1)];

    term_matrix = p2_mat .* phi_mat .* y_vec;

    inner_sum = sum(term_matrix, 2); 

    freq_power_sq = abs(inner_sum) .^ 2;

    energy_terms = (p1_vec .^ 2) .* freq_power_sq;

    gama_tl = sum(energy_terms);

    if isnan(gama_tl)
        gama_tl = 0; 
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
    u_n1 = exp(1j * phaseFactor * pi * l * n1 / (O1 * N1));
  
    v = kron(u_n1, u_n2);
    v = v(:); % Ensure column vector
end

function W_l = computePrecodingMatrix(N1, N2, N3, O1, O2, L, Mv, ...
    n1, n2, n3l, p1l, p2l, philif, i11, ...
    t, l)

    y_tlf = computeRotatedDFTPhase(n3l, N3, t);
    gama_tl = computeGamatl(L, Mv, p1l, y_tlf, l, p2l, philif);
    norm_factor = 1/(sqrt(N1*N2*gama_tl));

    q1 = i11(1);
    q2 = i11(2);
    [m1, m2] = computeM1M2(n1, n2, q1, q2, O1, O2);

    sum_first_matrix = 0;
    sum_second_matrix = 0;

    for i = 0:L - 1
        idx = i + 1; 
        
        % Generate the DFT beam for the current index
        % m1(idx) corresponds to 'l' in computeBeam, m2(idx) to 'm'
        v_lm = computeBeam(m1(idx), m2(idx), N1, N2, O1, O2, 2);

        firstValue = p1l(l, 1);
        lastValue = p1l(l, 2);

        freq_power_first = 0;
        freq_power_second = 0;

        for f = 0:Mv-1
            f_idx = f + 1;
            freq_power_first = freq_power_first + y_tlf(l, f_idx) * p2l(l, idx, f_idx) * philif(l, idx, f_idx);
            freq_power_second = freq_power_second + y_tlf(l, f_idx) * p2l(l, idx + L, f_idx) * philif(l, idx + L, f_idx);
        end

        sum_first_matrix = sum_first_matrix + v_lm * firstValue * freq_power_first;
        sum_second_matrix = sum_second_matrix + v_lm * lastValue * freq_power_second;
    end

    W_l = norm_factor*[sum_first_matrix; sum_second_matrix];
end