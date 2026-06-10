classdef customPDSCHConfig < nrPDSCHConfig
    properties
        MCSIndex
        CodebookConfig = struct() 
        Indices = struct('i1', {cell(1,4)}, 'i2', {cell(1,2)})
        TargetCodeRate;
    end
    
    properties (Access = private)
        pMCSIndex 
    end

    methods
        % --- CONSTRUCTOR ---
        function obj = customPDSCHConfig()
            obj@nrPDSCHConfig();
            obj.Modulation = 'QPSK';
            obj.TargetCodeRate = 490/1024;
        end

        % --- SETTER/GETTER cho MCSIndex ---
        function obj = setMCS(obj, val)
            obj.pMCSIndex = val;
            [mod, rate] = obj.lookupMCS(val);
            obj.Modulation = mod;          
            obj.TargetCodeRate = rate;     
        end

        function val = get.MCSIndex(obj)
            val = obj.pMCSIndex;
        end
    end

    methods (Access = private)
        function [modType, codeRate] = lookupMCS(~, mcsIndex)
            persistent mcsTable
            if isempty(mcsTable)
                % [MCS Index | Modulation Order (Qm) | Target Code Rate R x 1024]
                % Dữ liệu được trích xuất chính xác từ Table 5.1.3.1-2
                mcsTable = [
                    0    2    120;
                    1    2    193;
                    2    2    308;
                    3    2    449;
                    4    2    602;
                    5    4    378;
                    6    4    434;
                    7    4    490;
                    8    4    553;
                    9    4    616;
                    10   4    658;
                    11   6    466;
                    12   6    517;
                    13   6    567;
                    14   6    616;
                    15   6    666;
                    16   6    719;
                    17   6    772;
                    18   6    822;
                    19   6    873;
                    20   8    682.5; % Bắt đầu 256QAM
                    21   8    711;
                    22   8    754;
                    23   8    797;
                    24   8    841;
                    25   8    885;
                    26   8    916.5;
                    27   8    948
                ];
                % Các Index từ 28-31 là 'reserved' nên không đưa vào bảng tra cứu data
            end
            
            idx = find(mcsTable(:,1) == mcsIndex, 1);
            if isempty(idx), idx = 1; end
            
            Qm = mcsTable(idx, 2);
            codeRate = mcsTable(idx, 3) / 1024;
            
            mods = containers.Map([2, 4, 6, 8], {'QPSK', '16QAM', '64QAM', '256QAM'});
            if isKey(mods, Qm), modType = mods(Qm); else, modType = 'QPSK'; end
        end
    end

    methods (Access = public)

        function [G] = calculateManualG(obj)
            % --- 1. Basic Config ---
            numPRB = length(obj.PRBSet);
            numLayers = obj.NumLayers; 
            dmrsConfig = obj.DMRS;
            nSC = 12; 
            pdschLen = obj.SymbolAllocation(2);

            % --- 2. DMRS Symbol Count ---
            configAddPos = dmrsConfig.DMRSAdditionalPosition;
            if pdschLen < 4, m=0; elseif pdschLen < 8, m=1; elseif pdschLen < 10, m=2; else, m=3; end
            actualAddPos = min(configAddPos, m);
            numDMRSSymbols = 1 + actualAddPos; 
            if dmrsConfig.DMRSLength == 2, numDMRSSymbols = numDMRSSymbols * 2; end
            
            % --- 3. DMRS Overhead Per PRB ---
            cdmGroups = dmrsConfig.NumCDMGroupsWithoutData;
            if dmrsConfig.DMRSConfigurationType == 1, ov=6; else, ov=4; end
            overheadPerSym = cdmGroups * ov;
            dmrsOverhead_PerPRB = overheadPerSym * numDMRSSymbols;

            % --- 4. Calculate Total Reserved REs (Intersect logic) ---
            if isempty(obj.ReservedRE)
                numReversedRE = 0;
            else
                maxWidth = max(obj.PRBSet) * 12 + 1000;
                [k_res, l_res] = ind2sub([maxWidth, 14], obj.ReservedRE);
                
                min_k = min(obj.PRBSet) * 12 + 1;
                max_k = (max(obj.PRBSet) + 1) * 12;
                min_l = obj.SymbolAllocation(1) + 1; 
                max_l = obj.SymbolAllocation(1) + obj.SymbolAllocation(2);
                
                valid_k = (k_res >= min_k) & (k_res <= max_k);
                valid_l = (l_res >= min_l) & (l_res <= max_l);
                
                numReversedRE = sum(valid_k & valid_l);
            end

            % --- 5. Per PRB Calculation (FIXED HERE) ---
            totalRE_OnePRB = nSC * pdschLen;
            
            reAvailable_OnePRB = totalRE_OnePRB - dmrsOverhead_PerPRB; 

            % Apply 3GPP Rule (Floor 156)
            reData_PerPRB = min(156, reAvailable_OnePRB);
            
            % --- 6. Total Calculation ---
            totalReForPDSCH = reData_PerPRB * numPRB * numLayers;
            
            % --- 7. Subtract Holes (Reserved & PTRS) ---
            [totalPTRS_RE] = calculateManualPTRSCount(obj);
            
            totalReForPDSCH = totalReForPDSCH - totalPTRS_RE - numReversedRE;

            % --- 8. Final G ---
            switch obj.Modulation
                case 'QPSK',    Qm = 2;
                case '16QAM',   Qm = 4;
                case '64QAM',   Qm = 6;
                case '256QAM',  Qm = 8;
                case '1024QAM', Qm = 10;
                otherwise,      Qm = 2;
            end

            G = totalReForPDSCH * Qm;
        end
        
    end
end