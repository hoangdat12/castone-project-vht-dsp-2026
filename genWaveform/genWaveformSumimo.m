function outWaveform = genWaveformSumimo(baseConfig, W)
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

    inputBits = ones(TBS, 1);

    fprintf('Số lượng Bits đầu vào (TBS)::: %d bits\n', TBS);

    % -----------------------------------------------------------------
    % PDSCH Modulation
    % -----------------------------------------------------------------
    [layerMappedSym, pdschInd] = myPDSCHEncode(pdsch, carrier, inputBits);

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

    portGrid_flat = layerGrid_flat * (W.'); 
    portGrid = reshape(portGrid_flat, K, symbolsPerSlot, nPorts);

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
    outWaveform = ofdmModulationAndWaveformExport(frameGrid, baseConfig.FILE_NAME, W);
end