function [dmrssymbolset, ldash] = lookupDMRSTable(carrierConfig, pdschConfig)
% -----------------------------------------------------------
% LOOKUPDMRSTABLE: Determines Time-Domain DMRS Positions
% -----------------------------------------------------------
% Reference: 3GPP TS 38.211, Tables 7.4.1.1.2-3 & 7.4.1.1.2-4.
%
% Inputs:
%   carrierConfig : Struct {SymbolsPerSlot}
%   pdschConfig   : Struct {SymbolAllocation, MappingType, DMRS...}
%       - SymbolAllocation: [Start, Length]
%       - MappingType     : 'A' (Slot-based) or 'B' (Symbol-based)
%       - DMRS.DMRSLength : 1 (Single) or 2 (Double)
%
% Outputs:
%   dmrssymbols : [1 x N] Vector of 0-based symbol indices for DM-RS.
%   ldash       : [1 x N] Delta indicator for Double Symbol pairs.
%                 0 = First symbol of pair, 1 = Second symbol.
% -----------------------------------------------------------

    % =====================================================================
    % DEFINE LOOKUP TABLES (TS 38.211 Section 7.4.1.1.2)
    % =====================================================================
    % Structure: Cell Array {Rows, Cols}
    %   - Rows: Duration 'ld' in symbols (1 to 14).
    %   - Cols: DMRS Additional Position (0, 1, 2, 3).
    %   - Content: Relative symbol indices (0 represents l0 or start).
    % =====================================================================

    % -----------------------------------------------------------
    % 1. Single Symbol Type A (Table 7.4.1.1.2-3)
    % Note: '0' is a placeholder for l0 (which is 2 or 3).
    % -----------------------------------------------------------
    dmrs_singleA = {
        [],[],  [],  [];                %  1 symbol
        [],[],  [],  [];                %  2 symbol
        0,  0,  0,    0;                %  3 symbol
        0,  0,  0,    0;                %  4 symbol
        0,  0,  0,    0;                %  5 symbol
        0,  0,  0,    0;                %  6 symbol
        0,  0,  0,    0;                %  7 symbol
        0,  [0,7],  [0,7],  [0,7];      %  8 symbol
        0,  [0,7],  [0,7],  [0,7];      %  9 symbol
        0,  [0,9], [0,6,9], [0,6,9];    % 10 symbol
        0,  [0,9], [0,6,9], [0,6,9];    % 11 symbol
        0,  [0,9], [0,6,9], [0,5,8,11]; % 12 symbol
        0,  [0,11],[0,7,11],[0,5,8,11]; % 13 symbol
        0,  [0,11],[0,7,11],[0,5,8,11]; % 14 symbol
    };

    % -----------------------------------------------------------
    % 2. Single Symbol Type B (Table 7.4.1.1.2-3)
    % Note: Values are relative to PDSCH Start Symbol.
    % -----------------------------------------------------------
    dmrs_singleB = {
        [],[],  [],  [];            %  1 symbol
        0, 0,   0,   0;             %  2 symbol
        0, 0,   0,   0;             %  3 symbol
        0, 0,   0,   0;             %  4 symbol
        0,[0,4],[0,4],  [0,4];      %  5 symbol
        0,[0,4],[0,4],  [0,4];      %  6 symbol 
        0,[0,4],[0,4],  [0,4];      %  7 symbol 
        0,[0,6],[0,3,6],[0,3,6];    %  8 symbol
        0,[0,7],[0,4,7],[0,4,7];    %  9 symbol     
        0,[0,7],[0,4,7],[0,4,7];    % 10 symbol             
        0,[0,8],[0,4,8],[0,3,6,9];  % 11 symbol         
        0,[0,9],[0,5,9],[0,3,6,9];  % 12 symbol             
        0,[0,9],[0,5,9],[0,3,6,9];  % 13 symbol
        [],[],  [],  [];            % 14 symbol
    };

    % -----------------------------------------------------------
    % 3. Double Symbol Type A (Table 7.4.1.1.2-4)
    % -----------------------------------------------------------
    dmrs_doubleA = {
        [],[], [];     %  1 symbol
        [],[], [];     %  2 symbol
        [],[], [];     %  3 symbol
        0, 0, [];      %  4 symbol
        0, 0, [];      %  5 symbol
        0, 0, [];      %  6 symbol
        0, 0, [];      %  7 symbol
        0, 0, [];      %  8 symbol
        0, 0, [];      %  9 symbol
        0,[0,8], [];   % 10 symbol
        0,[0,8], [];   % 11 symbol
        0,[0,8], [];   % 12 symbol
        0,[0,10], [];  % 13 symbol
        0,[0,10], [];  % 14 symbol
    };

    % -----------------------------------------------------------
    % 4. Double Symbol Type B (Table 7.4.1.1.2-4)
    % -----------------------------------------------------------
    dmrs_doubleB = {
        [],[], [];    %  1 symbol
        [],[], [];    %  2 symbol
        [],[], [];    %  3 symbol
        [],[], [];    %  4 symbol
        0, 0, [];     %  5 symbol 
        0, 0, [];     %  6 symbol 
        0, 0, [];     %  7 symbol 
        0,[0,5], [];  %  8 symbol 
        0,[0,5], [];  %  9 symbol 
        0,[0,7], [];  % 10 symbol 
        0,[0,7], [];  % 11 symbol 
        0,[0,8], [];  % 12 symbol 
        0,[0,8], [];  % 13 symbol 
        [],[], [];    % 14 symbol
    };

    % =====================================================================
    % CONFIGURATION PARSING & TABLE SELECTION
    % =====================================================================
    dmrsConfig = pdschConfig.DMRS;
    symbPerSlot = carrierConfig.SymbolsPerSlot;
    
    % Default to Mapping Type A if not specified
    isTypeA = strcmpi(pdschConfig.MappingType, 'A');
    
    % -----------------------------------------------------------
    % Select Table based on DMRS Length (1 or 2) and Mapping Type
    % -----------------------------------------------------------
    if dmrsConfig.DMRSLength == 1
        if isTypeA
            selectedTable = dmrs_singleA;
        else
            selectedTable = dmrs_singleB;
        end
    else
        % Double Symbol (Length 2)
        if isTypeA
            selectedTable = dmrs_doubleA;
        else
            selectedTable = dmrs_doubleB;
        end
    end

    % -----------------------------------------------------------
    % Determine l0 (First DMRS Position) for Type A
    % l0 is absolute symbol index (2 or 3) determined by RRC.
    % -----------------------------------------------------------
    if isTypeA
        if (dmrsConfig.DMRSTypeAPosition == 3 || strcmpi(dmrsConfig.DMRSTypeAPosition, 'pos3'))
            l0_typeA = 3;
        else
            l0_typeA = 2; % Default pos2
        end
    end

    % -----------------------------------------------------------
    % Determine Column Index
    % Maps AdditionalPosition {0,1,2,3} to indices {1,2,3,4}
    % -----------------------------------------------------------
    colIdx = dmrsConfig.DMRSAdditionalPosition + 1;

    % =====================================================================
    % DURATION CALCULATION (ld)
    % =====================================================================
    % PDSCH Allocation: [Start, Length]
    nPDSCHStart = pdschConfig.SymbolAllocation(1);
    nPDSCHLen   = pdschConfig.SymbolAllocation(2);
    
    % Define the valid symbol range for validation later
    symbolRange = nPDSCHStart : (nPDSCHStart + nPDSCHLen - 1);
    
    % -----------------------------------------------------------
    % Calculate 'ld' (Duration in symbols for table lookup)
    % Type A: ld = End Symbol Index (referenced from slot start)
    % Type B: ld = Actual PDSCH Length
    % -----------------------------------------------------------
    if isTypeA
        ld = nPDSCHStart + nPDSCHLen; 
    else
        ld = nPDSCHLen;
    end

    % Safety Check: Ensure lookup indices are within table bounds
    if ld > size(selectedTable, 1) || colIdx > size(selectedTable, 2)
        dmrssymbolset = []; ldash = [];
        return; 
    end

    % -----------------------------------------------------------
    % Retrieve Raw Positions
    % rawSymbols contains relative indices or '0' placeholders
    % -----------------------------------------------------------
    rawSymbols = selectedTable{ld, colIdx};

    if isempty(rawSymbols)
        dmrssymbolset = []; ldash = [];
        return;
    end

    % =====================================================================
    % MAPPING & EXPANSION
    % =====================================================================
    
    % -----------------------------------------------------------
    % Adjust Positions based on Mapping Type
    % -----------------------------------------------------------
    if isTypeA
        dmrssymbolset = rawSymbols;
        % Replace placeholder '0' with actual l0 value (2 or 3)
        if ~isempty(dmrssymbolset)
             dmrssymbolset(dmrssymbolset == 0) = l0_typeA;
        end
    else
        % Type B: Values are relative to PDSCH Start
        dmrssymbolset = rawSymbols + nPDSCHStart;
    end

    % -----------------------------------------------------------
    % Double Symbol Expansion (DMRS Length = 2)
    % -----------------------------------------------------------
    if dmrsConfig.DMRSLength == 2
        % Expand each symbol 'l' into pair '[l, l+1]'
        % Matrix construction:
        %   Row 1: Original symbols
        %   Row 2: Original + 1
        dmrssymbolset = [dmrssymbolset; dmrssymbolset + 1];
        
        % Flatten column-wise to keep pairs together: [l1, l1+1, l2, l2+1...]
        dmrssymbolset = dmrssymbolset(:).'; 
        
        % ldash: 0 for first symbol, 1 for second symbol of the pair
        ldash = repmat([0, 1], 1, length(dmrssymbolset)/2);
    else
        ldash = zeros(size(dmrssymbolset));
    end

    % =====================================================================
    % VALIDATION
    % =====================================================================
    % Filter out symbols that fall outside the PDSCH allocation or Slot
    validMask = ismember(dmrssymbolset, symbolRange) & (dmrssymbolset < symbPerSlot);
    
    if ~any(validMask)
        warning('No valid DM-RS symbols found within PDSCH allocation.');
    end
    
    dmrssymbolset = dmrssymbolset(validMask);
    ldash = ldash(validMask);
end