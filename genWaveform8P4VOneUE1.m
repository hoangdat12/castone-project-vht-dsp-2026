clear; clc; close all;

setupPath();

ALL_Case = [
    % Case 1: Default
    struct('desc', 'Case 1: Default', ...
           'NLAYERS', 4, 'MCS', 27, ...
           'SUBCARRIER_SPACING', 30, 'NSIZE_GRID', 273, 'CYCLIC_PREFIX', "normal", ...
           'NSLOT', 0, 'NFRAME', 0, 'NCELL_ID', 20, ...
           'DMRS_CONFIGURATION_TYPE', 1, 'DMRS_TYPEA_POSITION', 2, 'DMRS_NUMCDMGROUP_WITHOUT_DATA', 2, ...
           'DMRS_LENGTH', 1, 'DMRS_ADDITIONAL_POSITION', 1, ...
           'PDSCH_MAPPING_TYPE', 'A', 'PDSCH_RNTI', 20000, 'PDSCH_PRBSET', 0:272, 'PDSCH_START_SYMBOL', 0, ...
           'FILE_NAME', 'CASE2_UE1_PDSCH_Waveform_8P4V');
];    

W = [
    0.1768 + 0.0000i,  0.1768 + 0.0000i,  0.1768 + 0.0000i,  0.1768 + 0.0000i;
    0.1768 + 0.0000i,  0.0000 + 0.1768i,  0.1768 + 0.0000i,  0.0000 + 0.1768i;
    0.1768 + 0.0000i, -0.1768 + 0.0000i,  0.1768 + 0.0000i, -0.1768 + 0.0000i;
    0.1768 + 0.0000i, -0.0000 - 0.1768i,  0.1768 + 0.0000i, -0.0000 - 0.1768i;
    0.1768 + 0.0000i,  0.1768 + 0.0000i, -0.1768 + 0.0000i, -0.1768 + 0.0000i;
    0.1768 + 0.0000i,  0.0000 + 0.1768i, -0.1768 + 0.0000i, -0.0000 - 0.1768i;
    0.1768 + 0.0000i, -0.1768 + 0.0000i, -0.1768 + 0.0000i,  0.1768 - 0.0000i;
    0.1768 + 0.0000i, -0.0000 - 0.1768i, -0.1768 + 0.0000i,  0.0000 + 0.1768i
];

disp("PMI Matrix 1");
disp(W);

vsa_normalize_matrix(W);

outWaveforms = cell(length(ALL_Case), 1);

for caseIdx = 1:length(ALL_Case) 
    baseConfig = ALL_Case(caseIdx);

    % -----------------------------------------------------------------
    % Carrier Configuration
    % -----------------------------------------------------------------
    carrier = nrCarrierConfig;
    
    % Lấy dữ liệu từ struct hiện tại bằng ALL_Case(caseIdx).
    carrier.SubcarrierSpacing = baseConfig.SUBCARRIER_SPACING;  
    carrier.NSizeGrid         = baseConfig.NSIZE_GRID;
    carrier.CyclicPrefix      = baseConfig.CYCLIC_PREFIX;
    carrier.NSlot             = baseConfig.NSLOT;
    carrier.NFrame            = baseConfig.NFRAME;
    carrier.NCellID           = baseConfig.NCELL_ID;

    % -----------------------------------------------------------------
    % PDSCH Configuration
    % -----------------------------------------------------------------
    pdsch = customPDSCHConfig(); 
    
    pdsch.DMRS.DMRSConfigurationType     = baseConfig.DMRS_CONFIGURATION_TYPE; 
    pdsch.DMRS.DMRSTypeAPosition         = baseConfig.DMRS_TYPEA_POSITION; 
    pdsch.DMRS.NumCDMGroupsWithoutData   = baseConfig.DMRS_NUMCDMGROUP_WITHOUT_DATA;
    pdsch.DMRS.DMRSLength                = baseConfig.DMRS_LENGTH;
    pdsch.DMRS.DMRSAdditionalPosition    = baseConfig.DMRS_ADDITIONAL_POSITION; % <--- Ánh xạ trường mới thêm

    pdsch.NumLayers   = baseConfig.NLAYERS;
    pdsch.MappingType = baseConfig.PDSCH_MAPPING_TYPE;
    pdsch.RNTI        = baseConfig.PDSCH_RNTI;
    pdsch.PRBSet      = baseConfig.PDSCH_PRBSET;
    pdsch.SymbolAllocation = [baseConfig.PDSCH_START_SYMBOL, 14 - baseConfig.PDSCH_START_SYMBOL];

    % Table 5.1.3.1-2: MCS index table 2 for PDSCH - 138 214
    % https://www.etsi.org/deliver/etsi_ts/138200_138299/138214/18.06.00_60/ts_138214v180600p.pdf
    % In this code using TABLE 2
    pdsch = pdsch.setMCS(baseConfig.MCS);

    % -----------------------------------------------------------------
    % Generate Bits
    % -----------------------------------------------------------------
    TBS = manualCalculateTBS(pdsch);
    disp(TBS);
    inputBits = ones(TBS, 1);

    fprintf('Số lượng Bits đầu vào (TBS)::: %d bits\n', TBS);

    % -----------------------------------------------------------------
    % PDSCH Modulation
    % -----------------------------------------------------------------
    % [layerMappedSym, pdschInd] = myPDSCHEncode(pdsch, carrier, inputBits);
    % -----------------------------------------------------------------
    % PREPARATION & INDICES
    % -----------------------------------------------------------------
    % Generate PDSCH indices and information structure
    [pdschInd, G] = PDSCHIndices(carrier, pdsch);
    
    % -----------------------------------------------------------------
    % CODING CHAIN
    % -----------------------------------------------------------------
    % 1. CRC Encoding (Type 24A)
    crcEncoded = createCRC(inputBits, '24A');
    
    % 2. LDPC Base Graph Selection
    % Note: Requires 'baseGraphSelection' helper function
    bgn = baseGraphSelection(crcEncoded, pdsch.TargetCodeRate);
    
    % 3. Code Block Segmentation
    cbs = cbSegmentation(crcEncoded, bgn);
    
    % 4. LDPC Encoding
    ldpcEncodeds = nrLDPCEncode(cbs, bgn);

    % 5. Rate Matching
    % Redundancy version (RV) is set to 0 for initial transmission
    rv = 0;
    ratematched = nrRateMatchLDPC(ldpcEncodeds, G, rv, pdsch.Modulation, pdsch.NumLayers);

    % -----------------------------------------------------------------
    % SCRAMBLING & MODULATION
    % -----------------------------------------------------------------
    % Determine Scrambling ID (use Cell ID if pdsch.NID is empty)
    if isempty(pdsch.NID)
        nid = carrier.NCellID;
    else
        nid = pdsch.NID(1);
    end
    
    rnti = pdsch.RNTI;

    cinit = (double(rnti) * 2^15) + (double(0) * 2^14) + double(nid);
    
    % Apply Scrambling (XOR operation via modulo 2)
    scrambled = scrambling(ratematched, cinit);

    % Symbol Modulation (QPSK, 16QAM, etc.)
    modulated = modulation(scrambled, pdsch.Modulation);

    % -----------------------------------------------------------------
    % LAYER MAPPING
    % -----------------------------------------------------------------
    % Map symbols to spatial layers
    layerMappedSym = layerMapping(modulated, pdsch.NumLayers);    

    fprintf('Kích thước Symbols sau Layer Mapping [REs x Layers]::: %d x %d\n', size(layerMappedSym, 1), size(layerMappedSym, 2));

    dmrsSym = genDMRS(carrier, pdsch);
    dmrsInd = DMRSIndices(pdsch, carrier);

    fprintf('Kích thước DMRS Symbols [REs x Layers]::: %d x %d\n', size(dmrsSym, 1), size(dmrsSym, 2));
    
    % =========================================================================
    % 1. MAPPING LÊN LAYER GRID & 2. PRECODING SANG PORT GRID
    % =========================================================================
    nPorts = size(W, 1);
    nLayers = pdsch.NumLayers;
    K = carrier.NSizeGrid * 12;
    symbolsPerSlot = 14; % Mặc định 14 symbol/slot

    % Khởi tạo Frame Grid 3 chiều để lưu toàn bộ (K x 280 x 4)
    frameGrid = zeros(K, 280, nPorts); 

    currentSlotIdx = carrier.NSlot; 
    startSym = currentSlotIdx * symbolsPerSlot + 1;
    endSym = (currentSlotIdx + 1) * symbolsPerSlot;

    layerGrid = zeros(K, symbolsPerSlot, nLayers);

    for layer = 1:nLayers
        layerGrid(pdschInd(:, layer)) = layerMappedSym(:, layer);
        layerGrid(dmrsInd(:, layer))  = dmrsSym(:, layer);
    end

    layerGrid_flat = reshape(layerGrid, K * symbolsPerSlot, nLayers);

    antennaPortMapped = layerGrid_flat * (W.'); 
    portGrid = reshape(antennaPortMapped, K, symbolsPerSlot, nPorts);

    frameGrid(:, startSym:endSym, :) = portGrid;

    fprintf('[Toàn Frame] Kích thước [Subcarriers x Symbols x Ports]::: %d x %d x %d\n', ...
        size(frameGrid, 1), size(frameGrid, 2), size(frameGrid, 3));
    fprintf('[Toàn Frame] Số lượng RE mang dữ liệu (khác 0)::: %d REs\n', ...
        nnz(frameGrid));
    fprintf('[Toàn Frame] Tổng số RE trên Frame::: %d REs\n\n', ...
        numel(frameGrid));

    % =========================================================================
    % Export waveform
    % =========================================================================
    % ofdmModulationAndWaveformExport(frameGrid, baseConfig.FILE_NAME, W);
    NFFT       = 4096;
    numRe      = size(frameGrid, 1);
    numSymb    = size(frameGrid, 2);
    numTxPorts = size(W, 1);
    fileName   = baseConfig.FILE_NAME;

    % OFDM modulate một lần — dùng lại cho mọi mức SNR
    txdata1 = [];
    for p = 1:numTxPorts
        txDataF_Port = [frameGrid(numRe/2+1:end, :, p); ...
                        zeros(NFFT - numRe, numSymb);   ...
                        frameGrid(1:numRe/2, :, p)];
        txdata1 = [txdata1, ofdmModulation(txDataF_Port, NFFT)];
    end
    fprintf('Kich thuoc sau OFDM (1 Frame) [Mau x Port]: %d x %d\n\n', size(txdata1));

    centerFreq = 0;
    nFrame     = 5;
    scs        = 30000;

    % Xuất thêm file sạch làm reference
    [folder, name, ext] = fileparts(fileName);
    cleanFileName = fullfile(folder, sprintf('%s_CLEAN%s', name, ext));
    data_clean = repmat(txdata1, nFrame, 1);
    savevsarecordingmulti(cleanFileName, data_clean, NFFT*scs, centerFreq, numTxPorts);
    fprintf('Da xuat file sach: %s\n', cleanFileName);

    % Output trả về là file sạch
    outWaveform = data_clean;

    plotResourceGrid(frameGrid, carrier, pdsch, pdschInd, dmrsInd);
end


function plotResourceGrid(frameGrid, carrier, pdsch, pdschInd, dmrsInd)
% plotResourceGrid  Vẽ resource grid toàn frame bằng patch từng ô RE
%
%   plotResourceGrid(frameGrid, carrier, pdsch, pdschInd, dmrsInd)
%
%   Inputs:
%       frameGrid   - [K x totalSymbols x nPorts] — complex array sau precoding
%       carrier     - nrCarrierConfig
%       pdsch       - customPDSCHConfig
%       pdschInd    - PDSCH indices [nRE x nLayers], 1-based, vào layer grid
%       dmrsInd     - DMRS indices  [nDmrsRE x nLayers], 1-based, vào layer grid

    % ----------------------------------------------------------------
    % Tham số cơ bản
    % ----------------------------------------------------------------
    K              = size(frameGrid, 1);          % Số subcarrier = NSizeGrid*12
    totalSymbols   = size(frameGrid, 2);          % 280 symbol = 20 slot * 14
    symPerSlot     = 14;
    nSlots         = totalSymbols / symPerSlot;
    slotIdx        = carrier.NSlot;               % Slot chứa data (= 0)

    % ----------------------------------------------------------------
    % Xây dựng ma trận loại RE  [K x totalSymbols]
    %   0 = null (không có gì)
    %   1 = PDSCH data
    %   2 = DMRS
    % ----------------------------------------------------------------
    reType = zeros(K, totalSymbols, 'uint8');

    % Offset symbol của slot data trong frame
    symOffset = slotIdx * symPerSlot;   % = 0 nếu NSlot=0

    % Lấy cột đầu tiên (layer 0) — pattern RE giống nhau cho mọi layer
    pdschInd1 = pdschInd(:, 1);   % linear index vào [K x symPerSlot]
    dmrsInd1  = dmrsInd(:, 1);

    % Chuyển linear → (row=sc, col=sym_in_slot)
    [pdsch_sc, pdsch_sym] = ind2sub([K, symPerSlot], pdschInd1);
    [dmrs_sc,  dmrs_sym]  = ind2sub([K, symPerSlot], dmrsInd1);

    % Ghi vào frame (cộng symOffset)
    for i = 1:numel(pdsch_sc)
        reType(pdsch_sc(i), symOffset + pdsch_sym(i)) = 1;
    end
    for i = 1:numel(dmrs_sc)
        reType(dmrs_sc(i),  symOffset + dmrs_sym(i))  = 2;
    end

    % ----------------------------------------------------------------
    % Màu sắc — nền trắng
    %   0 null   → xám rất nhạt
    %   1 PDSCH  → xanh dương
    %   2 DMRS   → xanh lá
    % ----------------------------------------------------------------
    COLOR_NULL  = [0.93 0.93 0.93];
    COLOR_PDSCH = [0.22 0.54 0.87];
    COLOR_DMRS  = [0.11 0.62 0.46];

    colorMap = [COLOR_NULL; COLOR_PDSCH; COLOR_DMRS];   % 3 x 3

    % ----------------------------------------------------------------
    % Tạo RGB image [K x totalSymbols x 3] rồi dùng image()
    % ----------------------------------------------------------------
    rgbImg = zeros(K, totalSymbols, 3, 'single');
    for ch = 1:3
        layer = colorMap(:, ch);
        rgbImg(:, :, ch) = single(reshape(layer(reType(:) + 1), K, totalSymbols));
    end

    % ----------------------------------------------------------------
    % Figure — nền trắng
    % ----------------------------------------------------------------
    fig = figure('Name', 'NR Resource Grid — Full Frame', ...
                 'Color', [1 1 1], ...
                 'Position', [80 80 1400 700]);

    ax = axes('Parent', fig, ...
              'Color', [1 1 1], ...
              'XColor', [0.15 0.15 0.15], ...
              'YColor', [0.15 0.15 0.15], ...
              'GridColor', [0.7 0.7 0.7], ...
              'GridAlpha', 0.4, ...
              'FontName', 'Consolas', ...
              'FontSize', 9);

    % image() — trục X = symbol, trục Y = subcarrier
    image(ax, permute(rgbImg, [1 2 3]));

    % ----------------------------------------------------------------
    % Lưới PRB (mỗi 12 subcarrier = 1 PRB)
    % ----------------------------------------------------------------
    hold(ax, 'on');

    % Đường kẻ ngang PRB
    prbLines = (12:12:K-1) + 0.5;
    for y = prbLines
        plot(ax, [0.5, totalSymbols+0.5], [y y], ...
             'Color', [0.75 0.75 0.75], 'LineWidth', 0.3);
    end

    % Đường kẻ dọc slot
    for s = 1:nSlots-1
        x = s * symPerSlot + 0.5;
        plot(ax, [x x], [0.5, K+0.5], ...
             'Color', [0.55 0.55 0.55], 'LineWidth', 0.7);
    end

    % Highlight slot chứa data — viền cam đậm trên nền trắng
    xL = symOffset + 0.5;
    rectangle(ax, 'Position', [xL, 0.5, symPerSlot, K], ...
              'EdgeColor', [0.85 0.45 0.05], 'LineWidth', 2.0, ...
              'LineStyle', '--');

    hold(ax, 'off');

    % ----------------------------------------------------------------
    % Trục & nhãn
    % ----------------------------------------------------------------
    ax.YDir = 'normal';
    xlabel(ax, 'OFDM Symbol (slot × 14)', 'Color', [0.15 0.15 0.15], 'FontSize', 10);
    ylabel(ax, 'Subcarrier index',         'Color', [0.15 0.15 0.15], 'FontSize', 10);

    % Tick X: đánh số slot
    slotTicks  = (0:nSlots-1) * symPerSlot + symPerSlot/2 + 0.5;
    slotLabels = arrayfun(@(s) sprintf('Slot %d', s), 0:nSlots-1, 'UniformOutput', false);
    ax.XTick               = slotTicks;
    ax.XTickLabel          = slotLabels;
    ax.XTickLabelRotation  = 45;

    % Tick Y: đánh số PRB mỗi 24 PRB
    prbStep   = 24;
    prbTicks  = (0:prbStep:floor(K/12)-1) * 12 + 6;
    prbLabels = arrayfun(@(p) sprintf('PRB %d', p), 0:prbStep:floor(K/12)-1, 'UniformOutput', false);
    ax.YTick      = prbTicks;
    ax.YTickLabel = prbLabels;

    % ----------------------------------------------------------------
    % Tiêu đề
    % ----------------------------------------------------------------
    titleStr = sprintf('NR Resource Grid  |  SCS %d kHz  |  %d PRB  |  %d Slots  |  MCS %d (%s)  |  %d Layers', ...
        carrier.SubcarrierSpacing, carrier.NSizeGrid, nSlots, ...
        pdsch.MCSIndex, pdsch.Modulation, pdsch.NumLayers);
    title(ax, titleStr, 'Color', [0.10 0.10 0.10], 'FontSize', 10, 'FontName', 'Consolas');

    % ----------------------------------------------------------------
    % Thống kê RE
    % ----------------------------------------------------------------
    nPdsch = sum(reType(:) == 1);
    nDmrs  = sum(reType(:) == 2);
    nNull  = sum(reType(:) == 0);
    nTotal = K * totalSymbols;

    statsStr = sprintf('PDSCH: %d RE (%.1f%%)   DMRS: %d RE (%.1f%%)   Null: %d RE (%.1f%%)', ...
        nPdsch, 100*nPdsch/nTotal, ...
        nDmrs,  100*nDmrs/nTotal,  ...
        nNull,  100*nNull/nTotal);

    annotation(fig, 'textbox', [0.01 0.01 0.98 0.04], ...
        'String', statsStr, ...
        'Color',           [0.15 0.15 0.15], ...
        'BackgroundColor', [0.95 0.95 0.95], ...
        'EdgeColor',       [0.75 0.75 0.75], ...
        'FontName', 'Consolas', 'FontSize', 8.5, ...
        'HorizontalAlignment', 'center', ...
        'FitBoxToText', false);

    % ----------------------------------------------------------------
    % Legend
    % ----------------------------------------------------------------
    hold(ax, 'on');
    hNull  = patch(ax, NaN, NaN, COLOR_NULL,  'EdgeColor', [0.7 0.7 0.7], ...
                   'DisplayName', 'Null RE');
    hPdsch = patch(ax, NaN, NaN, COLOR_PDSCH, 'EdgeColor', 'none', ...
                   'DisplayName', sprintf('PDSCH data (%d RE)', nPdsch));
    hDmrs  = patch(ax, NaN, NaN, COLOR_DMRS,  'EdgeColor', 'none', ...
                   'DisplayName', sprintf('DMRS (%d RE)', nDmrs));
    hSlot  = plot(ax, NaN, NaN, '--', 'Color', [0.85 0.45 0.05], 'LineWidth', 2.0, ...
                  'DisplayName', sprintf('Active slot (Slot %d)', slotIdx));
    hold(ax, 'off');

    legend(ax, [hNull, hPdsch, hDmrs, hSlot], ...
               'Location',  'northeast', ...
               'TextColor', [0.15 0.15 0.15], ...
               'Color',     [1 1 1], ...
               'EdgeColor', [0.75 0.75 0.75], ...
               'FontName',  'Consolas', 'FontSize', 8.5);

    % ----------------------------------------------------------------
    % Zoom callback: khi zoom vào < 56 symbol → kẻ lưới từng symbol
    % ----------------------------------------------------------------
    zoom(fig, 'on');
    set(zoom(fig), 'ActionPostCallback', @(src, evd) zoomDetailCallback(ax, evd, symPerSlot));

    fprintf('[plotResourceGrid] Vẽ xong: %d subcarrier × %d symbol | %d PRB\n', ...
        K, totalSymbols, carrier.NSizeGrid);
end


% ----------------------------------------------------------------
% Callback zoom
% ----------------------------------------------------------------
function zoomDetailCallback(ax, ~, symPerSlot)
    xlim_cur   = ax.XLim;
    visSymbols = diff(xlim_cur);
    if visSymbols < 56
        hold(ax, 'on');
        for x = floor(xlim_cur(1)):ceil(xlim_cur(2))
            if mod(x - 0.5, 1) < 0.01
                plot(ax, [x+0.5, x+0.5], ax.YLim, ...
                    'Color', [0.80 0.80 0.80], 'LineWidth', 0.25, ...
                    'HandleVisibility', 'off', 'Tag', 'symGrid');
            end
        end
        hold(ax, 'off');
    else
        delete(findobj(ax, 'Tag', 'symGrid'));
    end
end