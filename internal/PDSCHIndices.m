function [indices, G] = PDSCHIndices(carrier, pdsch)
% -----------------------------------------------------------
% PDSCHINDICES: Generates Resource Element (RE) Indices for PDSCH
% -----------------------------------------------------------
% This function calculates the linear indices for PDSCH mapping on the 
% carrier grid, accounting for DMRS rate matching and reserved resources.
%
% Inputs:
%   carrier : Struct {NStartGrid, NSizeGrid, SymbolsPerSlot}
%   pdsch   : Struct {NStartBWP, PRBSet, SymbolAllocation, DMRS, ...}
%
% Outputs:
%   indices : Matrix [TotalREs x NumLayers] of 1-based linear indices.
%   G       : Transport Block size G.
% -----------------------------------------------------------

    % -----------------------------------------------------------
    % BASIC SETUP & GRID ALIGNMENT
    % -----------------------------------------------------------
    % Determine BWP starting PRB relative to Carrier Grid.
    if ~isempty(pdsch.NStartBWP)
        nStartBWP = double(pdsch.NStartBWP);
    else
        nStartBWP = double(carrier.NStartGrid); 
    end
    nStartGrid = double(carrier.NStartGrid);
    
    % Offset to align BWP-based PRB indices to the global Carrier Grid.
    gridOffset = nStartBWP - nStartGrid;
    
    % Grid Dimensions
    nSizeGrid       = double(carrier.NSizeGrid);
    nRBSC           = 12; % Subcarriers per PRB
    
    % Calculate stride for Port/Layer offsets (Size of one full resource grid)
    nTotalRE_PerPort = nRBSC * nSizeGrid * carrier.SymbolsPerSlot;

    % -----------------------------------------------------------
    % RESOURCE ALLOCATION & FILTERING
    % -----------------------------------------------------------
    % Get physical PRB allocation (handles VRB-to-PRB interleaving if active).
    prbsetRaw = getPRBAllocation(pdsch, carrier);
    
    % Define Time-Domain Symbol Allocation [Start, Length]
    if isempty(pdsch.SymbolAllocation)
        SymbolAllocation = [];
    else
        SymbolAllocation = pdsch.SymbolAllocation(1) : (pdsch.SymbolAllocation(1) + pdsch.SymbolAllocation(2) - 1);
    end

    % Filter out PRBs overlapping with reserved resources.
    % validPRBs is a Cell Array indexed by (Symbol Index + 1).
    validPRBs = removeReservePRB(carrier, prbsetRaw, SymbolAllocation, pdsch.ReservedPRB);
    
    % Identify symbols containing DMRS (for Rate Matching).
    dmrssymbols = sort(lookupDMRSTable(carrier, pdsch));
    
    % Number of Spatial Layers (Transmission Ports)
    nports = double(pdsch.NumLayers);

    % -----------------------------------------------------------
    % DMRS RATE MATCHING LOGIC
    % -----------------------------------------------------------
    % PDSCH cannot be mapped to REs occupied by DMRS CDM groups.
    % cdmgroupsnodata : Number of CDM groups reserved (1, 2, or 3).
    % rawShift        : Frequency domain shift (usually based on CellID).
    % -----------------------------------------------------------
    cdmgroupsnodata = double(pdsch.DMRS.NumCDMGroupsWithoutData);
    rawShift = double(pdsch.DMRS.DeltaShifts);
    if isempty(rawShift), rawShift = 0; end 
    
    dmrsExcludedSC = []; 
    
    % -----------------------------------------------------------
    % Define DMRS Subcarrier Patterns
    % Type 1: Base [0,2,4,6,8,10] | Type 2: Base [0,1,6,7]
    % -----------------------------------------------------------
    if pdsch.DMRS.DMRSConfigurationType == 1
        basePattern = [0; 2; 4; 6; 8; 10]; 
        % CDM Group 0: Shift 0
        if cdmgroupsnodata >= 1, dmrsExcludedSC = [dmrsExcludedSC; mod(basePattern + rawShift, 12)]; end
        % CDM Group 1: Shift 1
        if cdmgroupsnodata >= 2, dmrsExcludedSC = [dmrsExcludedSC; mod(basePattern + 1 + rawShift, 12)]; end
    else
        % Type 2 (FD-Orthogonal pairs)
        basePattern = [0; 1; 6; 7];
        % CDM Group 0: Shift 0
        if cdmgroupsnodata >= 1, dmrsExcludedSC = [dmrsExcludedSC; mod(basePattern + rawShift, 12)]; end
        % CDM Group 1: Shift 2
        if cdmgroupsnodata >= 2, dmrsExcludedSC = [dmrsExcludedSC; mod(basePattern + 2 + rawShift, 12)]; end
        % CDM Group 2: Shift 4
        if cdmgroupsnodata >= 3, dmrsExcludedSC = [dmrsExcludedSC; mod(basePattern + 4 + rawShift, 12)]; end
    end
    dmrsExcludedSC = unique(dmrsExcludedSC);

    % -----------------------------------------------------------
    % MAPPING LOOP (LAYER 0 GENERATION)
    % -----------------------------------------------------------
    indices_layer0 = [];

    % Iterate through allocated symbols
    for s = SymbolAllocation
        % Default: All 12 subcarriers in a PRB are available
        validSC_in_PRB = (0:11)';
        
        % If current symbol contains DMRS, exclude DMRS subcarriers
        if ismember(s, dmrssymbols)
            validSC_in_PRB = setdiff(validSC_in_PRB, dmrsExcludedSC);
        end
        if isempty(validSC_in_PRB), continue; end

        % Retrieve allocated PRBs for this specific symbol
        currentPRBs = validPRBs{s + 1}; 
        currentPRBs = currentPRBs(:);
        if isempty(currentPRBs), continue; end

        % -----------------------------------------------------------
        % Calculate Linear Indices
        % -----------------------------------------------------------
        % + PRB Start Position (Absolute Subcarrier Index)
        prbStartSC_Grid = (currentPRBs + gridOffset) * nRBSC;
        
        % + Expand Subcarriers for all PRBs
        % Creates a matrix of absolute subcarrier indices
        allSC = repmat(validSC_in_PRB, 1, length(currentPRBs)) + ...
                repmat(prbStartSC_Grid', length(validSC_in_PRB), 1);
        
        % + Apply Symbol Offset
        % Formula: index = k + (l * NSizeGrid * 12)
        symbolOffset = s * nSizeGrid * nRBSC;
        currentIndices = allSC(:) + symbolOffset + 1; % +1 for MATLAB 1-based indexing
        
        indices_layer0 = [indices_layer0; currentIndices];
    end
    
    % -----------------------------------------------------------
    % Handle Reserved REs (Rate Matching Pattern)
    % -----------------------------------------------------------
    if ~isempty(pdsch.ReservedRE)
       % pdsch.ReservedRE usually assumed 0-based, convert to 1-based
       indices_layer0 = setdiff(indices_layer0, pdsch.ReservedRE + 1, 'stable');
    end

    % -----------------------------------------------------------
    % LAYER EXPANSION (SPATIAL MULTIPLEXING)
    % -----------------------------------------------------------
    Gd = numel(indices_layer0);
    
    if Gd > 0 && nports > 0
        % Calculate offsets for each layer
        % Layer i is shifted by i * TotalREs_PerPort
        layerOffsets = nTotalRE_PerPort * (0:nports-1);
        
        % Replicate Layer 0 indices and apply offsets
        indices = repmat(indices_layer0, 1, nports) + repmat(layerOffsets, Gd, 1);
        % indices = sort(indices); % Optional sorting
    else
        indices = zeros(0, nports);
    end
    
    % -----------------------------------------------------------
    % IF HAVE MORE THAN ONE OUTPUTS
    % -----------------------------------------------------------
    if nargout > 1
        modStr = pdsch.Modulation;
        if iscell(modStr), modStr = modStr{1}; end
        
        % Determine Bits per Symbol (Qm)
        switch modStr
            case 'QPSK',   Qm = 2;
            case '16QAM',  Qm = 4;
            case '64QAM',  Qm = 6;
            case '256QAM', Qm = 8;
            otherwise,     Qm = 2;
        end
        
        % G: Total Coded Bits = NumREs * NumLayers * Qm
        G = Gd * nports * Qm;
    end
end