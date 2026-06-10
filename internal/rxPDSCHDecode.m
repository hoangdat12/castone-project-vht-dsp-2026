function rxBits = rxPDSCHDecode(carrier, pdsch, rxWaveform, txWaveform, TBS)
    pdschInd = nrPDSCHIndices(carrier, pdsch);

    dmrsSym = nrPDSCHDMRS(carrier, pdsch);
    dmrsInd = nrPDSCHDMRSIndices(carrier, pdsch);

    % LÝ THUYẾT: Kênh truyền ma trận không có độ trễ lan truyền. 
    % Buộc offset = 0 để tránh nhiễu tương quan làm trượt cửa sổ FFT.
    offset = 0; 

    rxWaveformSync = rxWaveform(1+offset:end, :);

    samplesNeeded = length(txWaveform); 

    if size(rxWaveformSync, 1) < samplesNeeded
        padding = samplesNeeded - size(rxWaveformSync, 1);
        rxWaveformSync = [rxWaveformSync; zeros(padding, size(rxWaveformSync, 2))];
    end

    rxGrid = nrOFDMDemodulate(carrier, rxWaveformSync);
    rxGrid = rxGrid(1:carrier.NSizeGrid*12, 1:carrier.SymbolsPerSlot, :);

    [Hest, nVar] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym, ...
        'CDMLengths', pdsch.DMRS.CDMLengths, ... 
        'AveragingWindow', [1 1]);

    [pdschRx, pdschHest] = nrExtractResources(pdschInd, rxGrid, Hest);
    eqSymbols = nrEqualizeMMSE(pdschRx, pdschHest, nVar);

    % LÝ THUYẾT: Truyền phương sai nhiễu nVar thực tế từ kênh vào khối giải mã
    rxBits = PDSCHDecode(pdsch, carrier, eqSymbols, TBS, nVar);
end

% -----------------------------------------------------------------
% This function performs the full PDSCH decoding chain
% -----------------------------------------------------------------
function [out, hasError] = PDSCHDecode(pdsch, carrier, eqSymbols, TBS, nVar)

    % -----------------------------------------------------------------
    % DEMODULATION & DESCRAMBLING
    % -----------------------------------------------------------------
    demappedSym_Cell = nrLayerDemap(eqSymbols);
    sym_to_demod = demappedSym_Cell{1}; 

    % LÝ THUYẾT: Sử dụng trực tiếp nVar để tính LLR chuẩn xác
    rawLLR = nrSymbolDemodulate(sym_to_demod, pdsch.Modulation, nVar);

    if isempty(pdsch.NID)
        nid = carrier.NCellID; 
    else
        nid = pdsch.NID(1); 
    end
    
    c_seq_rx = nrPDSCHPRBS(nid, pdsch.RNTI, 0, length(rawLLR));
    descrambledBits = rawLLR .* (1 - 2*double(c_seq_rx));

    % -----------------------------------------------------------------
    % RATE RECOVERY
    % -----------------------------------------------------------------
    rv = 0; 
    raterecovered = nrRateRecoverLDPC(descrambledBits, TBS, pdsch.TargetCodeRate, ...
                                      rv, pdsch.Modulation, pdsch.NumLayers);

    % -----------------------------------------------------------------
    % DECODING CHAIN (LDPC & CRC)
    % -----------------------------------------------------------------
    crcEnc_dummy = zeros(TBS + 24, 1); 
    bgn_rx = baseGraphSelection(crcEnc_dummy, pdsch.TargetCodeRate);

    MAX_ITER = 25;
    [decBits, ~] = nrLDPCDecode(raterecovered, bgn_rx, MAX_ITER, ...
                        'Algorithm', 'Normalized min-sum', ...
                        'ScalingFactor', 0.75);

    [rxPart, ~] = nrCodeBlockDesegmentLDPC(decBits, bgn_rx, TBS + 24);
    [out, hasError] = nrCRCDecode(rxPart, '24A');
end