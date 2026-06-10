function TBS = manualCalculateTBS(pdsch)
    % ---------------------------------------------------------------------
    % 1. Tính số DMRS REs bị chiếm dụng trong 1 PRB cho MỘT OFDM Symbol
    % ---------------------------------------------------------------------
    if pdsch.DMRS.DMRSConfigurationType == 1
        % Type 1: Mỗi CDM group có 6 REs / symbol
        rePerSymbolPerCDM = 6; 
    else
        % Type 2: Mỗi CDM group có 4 REs / symbol
        rePerSymbolPerCDM = 4;
    end
    rePerSymbol = rePerSymbolPerCDM * pdsch.DMRS.NumCDMGroupsWithoutData;

    % ---------------------------------------------------------------------
    % 2. Tính TỔNG SỐ OFDM Symbols chứa DMRS trong 1 Slot
    % ---------------------------------------------------------------------
    % Số cụm DMRS = 1 (cụm gốc - Front-loaded) + Số cụm cộng thêm (Additional)
    numDmrsClusters = 1 + pdsch.DMRS.DMRSAdditionalPosition;
    
    % Tổng số Symbol = Độ dài 1 cụm (Length) x Số cụm
    numDmrsSymbols = pdsch.DMRS.DMRSLength * numDmrsClusters;

    % ---------------------------------------------------------------------
    % 3. Tính lượng RE dành cho Data (PDSCH)
    % ---------------------------------------------------------------------
    dmrsRePerPRB = rePerSymbol * numDmrsSymbols;
    
    % Tổng số REs của PRB dựa trên Symbol Allocation (thường là 14 * 12 = 168)
    pdschReTotalPerPRB = 12 * pdsch.SymbolAllocation(2);

    % Số REs còn lại dành cho PDSCH data (N'_RE)
    pdschRePerPRB = pdschReTotalPerPRB - dmrsRePerPRB;

    % Ràng buộc tối đa 156 REs / PRB (Theo 3GPP TS 38.214 - 5.1.3.2)
    numRE = min(156, pdschRePerPRB) * length(pdsch.PRBSet);

    % Xác định Qm (Modulation Order)
    switch pdsch.Modulation
        case 'QPSK',    Qm = 2;
        case '16QAM',   Qm = 4;
        case '64QAM',   Qm = 6;
        case '256QAM',  Qm = 8;
        case '1024QAM', Qm = 10;
        otherwise,      Qm = 2;
    end

    % Tính N_info theo công thức
    NInfo = numRE * pdsch.TargetCodeRate * Qm * pdsch.NumLayers;

    % ---------------------------------------------------------------------
    % 4. Tra bảng và tính TBS (Giữ nguyên logic chuẩn của bạn)
    % ---------------------------------------------------------------------
    if NInfo <= 3824
        n = max(3, floor(log2(NInfo)) - 6);
        NInfoPrime = max(24, (2^n) * floor(NInfo / (2^n)));
        tableTBS = [24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, ...
                128, 136, 144, 152, 160, 168, 176, 184, 192, 208, 224, 240, ...
                256, 272, 288, 304, 320, 336, 352, 368, 384, 408, 432, 456, ...
                480, 504, 528, 552, 576, 608, 640, 672, 704, 736, 768, 808, ...
                848, 888, 928, 984, 1032, 1064, 1128, 1160, 1192, 1224, 1256, ...
                1288, 1320, 1352, 1416, 1480, 1544, 1608, 1672, 1736, 1800, ...
                1864, 1928, 2024, 2088, 2152, 2216, 2280, 2408, 2472, 2536, ...
                2600, 2664, 2728, 2792, 2856, 2976, 3104, 3240, 3368, 3496, ...
                3624, 3752, 3824];
        validTBS = tableTBS(tableTBS >= NInfoPrime);
        TBS = validTBS(1);
    else
        n = floor(log2(NInfo - 24)) - 5;
        round_val = floor((NInfo - 24) / (2^n) + 0.5);
        NInfoPrime = max(3840, (2^n) * round_val);

        if pdsch.TargetCodeRate <= 1/4
            C = ceil((NInfoPrime + 24) / 3816);
            TBS = 8 * C * ceil((NInfoPrime + 24) / (8 * C)) - 24;
        else
            if NInfoPrime > 8424
                C = ceil((NInfoPrime + 24) / 8424);
                TBS = 8 * C * ceil((NInfoPrime + 24) / (8 * C)) - 24;
            else
                TBS = 8 * ceil((NInfoPrime + 24) / 8) - 24;
            end
        end
    end
end