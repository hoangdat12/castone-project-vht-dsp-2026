clear; clc; close all;

setupPath();

ALL_Case = [
    % Case 1: Default
    struct('desc', 'Case 1: Default', ...
           'NLAYERS', 4, 'MCS', 27, ...
           'SUBCARRIER_SPACING', 30, 'NSIZE_GRID', 273, 'CYCLIC_PREFIX', "normal", ...
           'NSLOT', 0, 'NFRAME', 0, 'NCELL_ID', 20, ...
           'DMRS_CONFIGURATION_TYPE', 1, 'DMRS_TYPEA_POSITION', 2, 'DMRS_NUMCDMGROUP_WITHOUT_DATA', 2, ...
           'DMRS_LENGTH', 2, 'DMRS_ADDITIONAL_POSITION', 1, ...
           'PDSCH_MAPPING_TYPE', 'A', 'PDSCH_RNTI', 20000, 'PDSCH_PRBSET', 0:272, 'PDSCH_START_SYMBOL', 0, ...
           'FILE_NAME', '2UE_Combine_PDSCH_Waveform_8P4V_ALL_Frame');
];

% -----------------------------------------------------------------
% Ma trận Trực giao được chọn ra từ hàm (findOrthognalW)
% -----------------------------------------------------------------
W1 = [
   0.1768 + 0.0000i   0.1768 + 0.0000i   0.1768 + 0.0000i   0.1768 + 0.0000i;
  -0.1768 + 0.0000i   0.0000 - 0.1768i  -0.1768 + 0.0000i   0.0000 - 0.1768i;
   0.1768 + 0.0000i  -0.1768 + 0.0000i   0.1768 + 0.0000i  -0.1768 + 0.0000i;
  -0.1768 + 0.0000i   0.0000 + 0.1768i  -0.1768 + 0.0000i   0.0000 + 0.1768i;
   0.0000 + 0.1768i   0.0000 + 0.1768i   0.0000 - 0.1768i   0.0000 - 0.1768i;
   0.0000 - 0.1768i   0.1768 + 0.0000i   0.0000 + 0.1768i  -0.1768 + 0.0000i;
   0.0000 + 0.1768i   0.0000 - 0.1768i   0.0000 - 0.1768i   0.0000 + 0.1768i;
   0.0000 - 0.1768i  -0.1768 + 0.0000i   0.0000 + 0.1768i   0.1768 + 0.0000i
];

W2 = [
   0.1768 + 0.0000i   0.1768 + 0.0000i   0.1768 + 0.0000i   0.1768 + 0.0000i;
   0.0000 + 0.1768i   0.1768 + 0.0000i   0.0000 + 0.1768i   0.1768 + 0.0000i;
  -0.1768 + 0.0000i   0.1768 + 0.0000i  -0.1768 + 0.0000i   0.1768 + 0.0000i;
   0.0000 - 0.1768i   0.1768 + 0.0000i   0.0000 - 0.1768i   0.1768 + 0.0000i;
   0.0000 + 0.1768i   0.0000 + 0.1768i   0.0000 - 0.1768i   0.0000 - 0.1768i;
  -0.1768 + 0.0000i   0.0000 + 0.1768i   0.1768 + 0.0000i   0.0000 - 0.1768i;
   0.0000 - 0.1768i   0.0000 + 0.1768i   0.0000 + 0.1768i   0.0000 - 0.1768i;
   0.1768 + 0.0000i   0.0000 + 0.1768i  -0.1768 + 0.0000i   0.0000 - 0.1768i
];

vsa_normalize_matrix(W1, W2);

% -----------------------------------------------------------------
% Tính lại điểm trực giao của 2 Ma trận dựa vào thuật toán
% -----------------------------------------------------------------
score = PMIPair(W1, W2);
fprintf(' * Giá trị phức (Complex)::: %8.4f %+.4fi\n', real(score), imag(score));
fprintf(' * Biên độ tuyệt đối (Abs)::: %8.4f\n\n', abs(score));

outWaveforms = cell(length(ALL_Case), 1);

for caseIdx = 1:length(ALL_Case)
    baseConfig = ALL_Case(caseIdx);
    outWaveforms{caseIdx} = genWaveformMumimo2UESameLayer(baseConfig, W1, W2);
end

function outWaveform = genWaveformMumimo2UESameLayer(baseConfig, W1, W2)
    nLayers = baseConfig.NLAYERS;
    numTxPorts = size(W1, 1);

    % -----------------------------------------------------------------
    % Carrier Configuration
    % -----------------------------------------------------------------
    carrier = nrCarrierConfig;
    
    carrier.SubcarrierSpacing = baseConfig.SUBCARRIER_SPACING;  
    carrier.NSizeGrid         = baseConfig.NSIZE_GRID;
    carrier.CyclicPrefix      = baseConfig.CYCLIC_PREFIX;
    carrier.NFrame            = baseConfig.NFRAME;
    carrier.NCellID           = baseConfig.NCELL_ID;
    % Xóa gán NSlot ở đây vì lát nữa sẽ gán động trong vòng lặp

    % -----------------------------------------------------------------
    % PDSCH Configuration (Không đổi)
    % -----------------------------------------------------------------
    % KHỞI TẠO PDSCH CHO UE 1
    pdsch1 = customPDSCHConfig(); 
    pdsch1.DMRS.DMRSConfigurationType   = baseConfig.DMRS_CONFIGURATION_TYPE; 
    pdsch1.DMRS.DMRSTypeAPosition       = baseConfig.DMRS_TYPEA_POSITION; 
    pdsch1.DMRS.NumCDMGroupsWithoutData = baseConfig.DMRS_NUMCDMGROUP_WITHOUT_DATA;
    pdsch1.DMRS.DMRSLength              = baseConfig.DMRS_LENGTH;
    pdsch1.DMRS.DMRSAdditionalPosition  = baseConfig.DMRS_ADDITIONAL_POSITION;
    pdsch1.NumLayers   = nLayers;
    pdsch1.MappingType = baseConfig.PDSCH_MAPPING_TYPE;
    pdsch1.RNTI        = baseConfig.PDSCH_RNTI;
    pdsch1.PRBSet      = baseConfig.PDSCH_PRBSET;
    pdsch1.SymbolAllocation = [baseConfig.PDSCH_START_SYMBOL, 14 - baseConfig.PDSCH_START_SYMBOL];
    pdsch1 = pdsch1.setMCS(baseConfig.MCS);
    pdsch1.DMRS.DMRSPortSet = 0 : nLayers - 1;
    pdsch1.DMRS.NSCID = 0;

    % KHỞI TẠO PDSCH CHO UE 2
    pdsch2 = customPDSCHConfig(); 
    pdsch2.DMRS.DMRSConfigurationType   = baseConfig.DMRS_CONFIGURATION_TYPE; 
    pdsch2.DMRS.DMRSTypeAPosition       = baseConfig.DMRS_TYPEA_POSITION; 
    pdsch2.DMRS.NumCDMGroupsWithoutData = baseConfig.DMRS_NUMCDMGROUP_WITHOUT_DATA;
    pdsch2.DMRS.DMRSLength              = baseConfig.DMRS_LENGTH;
    pdsch2.DMRS.DMRSAdditionalPosition  = baseConfig.DMRS_ADDITIONAL_POSITION;
    pdsch2.NumLayers   = nLayers;
    pdsch2.MappingType = baseConfig.PDSCH_MAPPING_TYPE;
    pdsch2.RNTI        = baseConfig.PDSCH_RNTI + 1; 
    pdsch2.PRBSet      = baseConfig.PDSCH_PRBSET;
    pdsch2.SymbolAllocation = [baseConfig.PDSCH_START_SYMBOL, 14 - baseConfig.PDSCH_START_SYMBOL];
    pdsch2 = pdsch2.setMCS(baseConfig.MCS);
    pdsch2.DMRS.DMRSPortSet = nLayers : numTxPorts - 1;
    pdsch2.DMRS.NSCID = 0;

    % =================================================================
    % TẠO BITS VÀ CHUẨN BỊ LƯỚI KHUNG (FRAME GRID)
    % =================================================================
    TBS1 = manualCalculateTBS(pdsch1);
    TBS2 = manualCalculateTBS(pdsch2);

    fprintf('Số lượng Bits đầu vào (TBS) 1 Slot của UE1::: %d bits\n', TBS1);
    fprintf('Số lượng Bits đầu vào (TBS) 1 Slot của UE2::: %d bits\n\n', TBS2);

    % Bit mồi (Có thể thay đổi ngẫu nhiên nếu muốn test BER thật)
    inputBits1 = ones(TBS1, 1);
    inputBits2 = zeros(TBS2, 1);

    % Thiết lập thông số Frame
    numSlots = 10 * (baseConfig.SUBCARRIER_SPACING / 15); % Ví dụ: 30kHz -> 20 slots
    symbolsPerSlot = 14; 
    K = carrier.NSizeGrid * 12;
    nPorts = numTxPorts;
    nLayers1 = pdsch1.NumLayers;
    nLayers2 = pdsch2.NumLayers;

    % Khởi tạo Grid rỗng cho toàn bộ Frame (K x 280 x nPorts)
    frameGrid = zeros(K, numSlots * symbolsPerSlot, nPorts); 

    fprintf('--- Bắt đầu lặp qua %d Slots để tạo tín hiệu chuẩn hóa ---\n', numSlots);

    % =========================================================================
    % VÒNG LẶP QUA TỪNG SLOT ĐỂ MAPPING VÀ PRECODING
    % =========================================================================
    for slotIdx = 0 : (numSlots - 1)
        
        % [QUAN TRỌNG NHẤT]: Cập nhật NSlot để DMRS đổi mã ngẫu nhiên
        carrier.NSlot = slotIdx;

        % 1. Sinh PDSCH Data & DMRS cho Slot hiện tại
        [layerMappedSym1, pdschInd1] = myPDSCHEncode(pdsch1, carrier, inputBits1);
        [layerMappedSym2, pdschInd2] = myPDSCHEncode(pdsch2, carrier, inputBits2);

        dmrsSym1 = genDMRS(carrier, pdsch1);
        dmrsInd1 = DMRSIndices(pdsch1, carrier);

        dmrsSym2 = genDMRS(carrier, pdsch2);
        dmrsInd2 = DMRSIndices(pdsch2, carrier);

        % 2. Khởi tạo Grid tạm cho Slot hiện tại
        layerGrid_UE1 = zeros(K, symbolsPerSlot, nLayers1);
        layerGrid_UE2 = zeros(K, symbolsPerSlot, nLayers2);

        % 3. Map PDSCH và DMRS cho UE 1 
        for layer = 1:nLayers1
            layerGrid_UE1(pdschInd1(:, layer)) = layerMappedSym1(:, layer);
            layerGrid_UE1(dmrsInd1(:, layer))  = dmrsSym1(:, layer);
        end

        % Map PDSCH và DMRS cho UE 2
        for layer = 1:nLayers2
            layerGrid_UE2(pdschInd2(:, layer)) = layerMappedSym2(:, layer);
            layerGrid_UE2(dmrsInd2(:, layer))  = dmrsSym2(:, layer);
        end

        % 4. Chuyển sang dạng ma trận 2D để Precoding
        layerGrid_flat_UE1 = reshape(layerGrid_UE1, K * symbolsPerSlot, nLayers1);
        layerGrid_flat_UE2 = reshape(layerGrid_UE2, K * symbolsPerSlot, nLayers2);

        % Precoding (Output size: [(K*14) x nPorts])
        portGrid_flat_UE1 = layerGrid_flat_UE1 * (W1.'); 
        portGrid_flat_UE2 = layerGrid_flat_UE2 * (W2.'); 

        % Trả lại thành lưới 3D
        portGrid_UE1 = reshape(portGrid_flat_UE1, K, symbolsPerSlot, nPorts);
        portGrid_UE2 = reshape(portGrid_flat_UE2, K, symbolsPerSlot, nPorts);

        % Cộng dồn dữ liệu 2 UE (MU-MIMO)
        portGrid_Combined = portGrid_UE1 + portGrid_UE2;

        % 5. Ghép slot vừa xong vào đúng vị trí trên FrameGrid
        startSym = slotIdx * symbolsPerSlot + 1;
        endSym   = (slotIdx + 1) * symbolsPerSlot;
        
        frameGrid(:, startSym:endSym, :) = portGrid_Combined;
        
    end % Kết thúc vòng lặp slot

    % =========================================================================
    % IN THÔNG BÁO VÀ EXPORT WAVEFORM
    % =========================================================================
    fprintf('\n[Toàn Frame] Kích thước [Subcarriers x Symbols x Ports]::: %d x %d x %d\n', ...
        size(frameGrid, 1), size(frameGrid, 2), size(frameGrid, 3));
    fprintf('[Toàn Frame] Số lượng RE mang dữ liệu (khác 0)::: %d REs\n', ...
        nnz(frameGrid));
    fprintf('[Toàn Frame] Tổng số RE trên Frame::: %d REs\n\n', ...
        numel(frameGrid));

    % Export
    outWaveform = ofdmModulationAndWaveformExport(frameGrid, baseConfig.FILE_NAME, W1);
end