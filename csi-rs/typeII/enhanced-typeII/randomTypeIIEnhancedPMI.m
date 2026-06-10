function PMI = randomTypeIIEnhancedPMI(cfg, nLayers) 
    paramCombination = cfg.CodeBookConfig.ParamCombination;
    R = cfg.CodeBookConfig.NumberOfPMISubbandsPerCQISubband;
    O1 = cfg.CodeBookConfig.O1;
    O2 = cfg.CodeBookConfig.O2;

    bwpStart = cfg.CarrierConfig.NStartGrid;
    bwpSize = cfg.CarrierConfig.NSizeGrid;
    subbandSize = cfg.CSIReportConfig.SubbandSize;

    % Compute the number of subbands
    numSubbands = ceil(bwpSize / subbandSize);
    N3 = computeN3(R, numSubbands, bwpStart, bwpSize, subbandSize);

    [L, Pv, beta] = gettingParamsFromParamCombination(paramCombination, nLayers);

    % Compute Mv
    Mv = ceil(Pv * N3 / R); 

    % 1. Spatial Basis Selection
    i11 = [randi([0, O1-1]), randi([0, O2-1])];
    i12 = 0; % Cố định 0 hoặc dùng randi([0, 15]) tuỳ thuộc cấu hình N1, N2
    
    % 2. Frequency Basis Selection
    if N3 > 19
        i15 = randi([0, 2*Mv - 1]);
        max_i16 = nchoosek(2*Mv - 1, Mv - 1) - 1;
    else
        i15 = 0; 
        if Mv > 1
            max_i16 = nchoosek(N3 - 1, Mv - 1) - 1;
        else
            max_i16 = 0;
        end
    end
    
    % 3. Khởi tạo các mảng theo từng lớp (Dạng cột: nLayers x 1)
    i16 = zeros(nLayers, 1); % Dạng mảng số giống mock payload của bạn
    i17 = cell(nLayers, 1);
    i18 = cell(nLayers, 1);
    i23 = cell(nLayers, 1);
    i24 = cell(nLayers, 1);
    i25 = cell(nLayers, 1);
    
    total_elements = 2 * L * Mv;
    K0 = ceil(beta * total_elements); 
    
    for l = 1:nLayers
        % i16: Chỉ báo tổ hợp vector tần số
        i16(l, 1) = randi([0, max_i16]);
        
        % Tạo Bitmap i17 với số lượng bít 1 ngẫu nhiên (từ 1 đến K0)
        num_nz = randi([1, min(K0, total_elements)]); 
        bitmap = zeros(1, total_elements);
        idx_nz = randperm(total_elements, num_nz); % Các vị trí (1-based) có giá trị 1
        bitmap(idx_nz) = 1; 
        i17{l, 1} = bitmap;
        
        % Chọn Hệ số mạnh nhất (Strongest Coefficient)
        % Phải nằm ở một trong các vị trí có bit = 1
        strongest_idx_in_nz = randi([1, num_nz]); % Chọn ngẫu nhiên 1 trong số các hệ số khác 0
        strongest_linear_idx = idx_nz(strongest_idx_in_nz); % Vị trí thực tế trong bitmap (1-based)
        
        % Định dạng i18 theo chuẩn (1 Layer: index số lượng / Multi-layer: index tuyến tính)
        if nLayers == 1
            i18{l, 1} = strongest_idx_in_nz - 1; 
        else
            i18{l, 1} = strongest_linear_idx - 1; 
        end
        
        % i23 (Wideband Amp): CHỈ 1 GIÁ TRỊ (cho pol yếu)
        i23{l, 1} = randi([1, 15]); 
        
        % i24 và i25 (Subband Amp & Phase): CHỈ STREAM CÁC GIÁ TRỊ CÒN LẠI
        stream_len = max(0, num_nz - 1);
        if stream_len > 0
            i24{l, 1} = randi([0, 7], 1, stream_len);
            i25{l, 1} = randi([0, 15], 1, stream_len);
        else
            i24{l, 1} = []; 
            i25{l, 1} = [];
        end
    end

    % 4. Đóng gói vào struct PMI (Khớp 100% với cách parse của computeInputs)
    if N3 <= 19
        PMI.i1 = {i11, i12, i16, i17, i18};
    else
        PMI.i1 = {i11, i12, i15, i16, i17, i18};
    end
    
    PMI.i2 = {i23, i24, i25};
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
        startOffset = mod(nBWPStart, subbandSize);
        if startOffset >= halfSB
            N3 = N3 + 1;
        else
            N3 = N3 + 2;
        end
        
        % --- Processing Middle Subbands ---
        if numSubbands > 2
            N3 = N3 + (numSubbands - 2) * 2;
        end
        
        % --- Processing the Last Subband ---
        if numSubbands > 1
            lastPRBIndex = nBWPStart + nBWPSize - 1;
            endPosMod = mod(1 + lastPRBIndex, subbandSize);
            if endPosMod == 0
                endPosMod = subbandSize; 
            end
            
            if endPosMod <= halfSB
                N3 = N3 + 1;
            else
                N3 = N3 + 2;
            end
        end
    else
        error('Invalid R value. R must be 1 or 2.');
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
    L_table = [2; 2; 4; 4; 4; 4; 6; 6];
    Beta_table = [1/4; 1/2; 1/4; 1/2; 3/4; 1/2; 1/2; 3/4];
    Pv_layers12 = [1/4; 1/4; 1/4; 1/4; 1/4; 1/2; 1/4; 1/4];
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