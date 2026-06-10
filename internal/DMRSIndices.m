function indices = DMRSIndices(pdsch, carrier)
% -----------------------------------------------------------
% BASIC CONFIGURATION & GRID ALIGNMENT
% -----------------------------------------------------------
    % -----------------------------------------------------------
    % Determine the BWP start relative to the Carrier Grid.
    % If NStartBWP is not defined, default to the Carrier Grid start.
    % -----------------------------------------------------------
    if ~isempty(pdsch.NStartBWP)
        nStartBWP = double(pdsch.NStartBWP);
    else
        nStartBWP = double(carrier.NStartGrid); 
    end
    nStartGrid = double(carrier.NStartGrid);
    
    % -----------------------------------------------------------
    % Calculate the offset to align BWP resources to the Carrier Grid.
    % gridOffset = NStartBWP - NStartGrid
    % -----------------------------------------------------------
    gridOffset = nStartBWP - nStartGrid;
    
    % -----------------------------------------------------------
    % Carrier Grid Dimensions.
    % nRBSC = 12 (Fixed for FR1/FR2 standard SCS).
    % -----------------------------------------------------------
    nSizeGrid = double(carrier.NSizeGrid);
    nSymbolsPerSlot = carrier.SymbolsPerSlot;
    nRBSC = 12; 
    
    % -----------------------------------------------------------
    % Calculate the stride size for the Port dimension.
    % This represents the total number of REs in a single antenna port grid.
    % Used to jump memory "pages" when calculating linear indices for Ports > 0.
    % -----------------------------------------------------------
    nTotalRE_PerPort = nRBSC * nSizeGrid * nSymbolsPerSlot;

% -----------------------------------------------------------
% RESOURCE ALLOCATION & FILTERING
% -----------------------------------------------------------
    % -----------------------------------------------------------
    % Retrieve the allocated PRBs for the PDSCH.
    % These indices are typically 0-based relative to the BWP.
    % -----------------------------------------------------------
    prbset = getPRBAllocation(pdsch, carrier);
    
    % -----------------------------------------------------------
    % Define the symbol range for the PDSCH duration.
    % SymbolAllocation = [StartSymbol, Length].
    % -----------------------------------------------------------
    SymbolAllocation = pdsch.SymbolAllocation(1) : (pdsch.SymbolAllocation(1) + pdsch.SymbolAllocation(2) - 1);
    
    % -----------------------------------------------------------
    % Filter out PRBs that overlap with Reserved Resources.
    % prbcell is a cell array where each index corresponds to a symbol.
    % -----------------------------------------------------------
    prbcell = removeReservePRB(carrier, prbset, SymbolAllocation, pdsch.ReservedPRB);
    
    % -----------------------------------------------------------
    % Identify which symbols within the slot contain DMRS.
    % Returns a sorted list of 0-based symbol indices.
    % -----------------------------------------------------------
    dmrssymbols = sort(lookupDMRSTable(carrier, pdsch));

% -----------------------------------------------------------
% DMRS PATTERN & PRE-CALCULATION
% -----------------------------------------------------------
    % -----------------------------------------------------------
    % Retrieve the subcarrier offsets for DMRS.
    % subLocs Matrix dimensions: [REs_per_PRB x nPorts].
    %   + Rows (rePerPRB): The subcarrier offsets within a PRB (e.g., 0, 2, 4...).
    %   + Cols (nPorts)  : The specific pattern for each antenna port.
    % -----------------------------------------------------------
    subLocs = pdsch.DMRS.DMRSSubcarrierLocations;
    [rePerPRB, nPorts] = size(subLocs);

    % -----------------------------------------------------------
    % Calculate total required rows for preallocation.
    % Iterates through valid DMRS symbols and sums the active PRBs.
    % totalRows = Sum(NumPRBs_at_Symbol * REs_per_PRB).
    % -----------------------------------------------------------
    totalRows = 0;
    for i = 1:length(dmrssymbols)
        sym = dmrssymbols(i);
        totalRows = totalRows + length(prbcell{sym+1}) * rePerPRB;
    end
    
    % -----------------------------------------------------------
    % Initialize the output matrix.
    % Rows    : Total number of DMRS REs (per port).
    % Columns : Number of Antenna Ports.
    % -----------------------------------------------------------
    indices = zeros(totalRows, nPorts);
    currentRow = 1;

% -----------------------------------------------------------
% MAIN GENERATION LOOP
% -----------------------------------------------------------
    % Iterate through every symbol containing DMRS
    for i = 1:length(dmrssymbols)
        l = dmrssymbols(i); % Current Symbol Index (0-13)
        
        currentPRBs = prbcell{l+1};
        if isempty(currentPRBs), continue; end
        
        % Iterate through every allocated PRB in the current symbol
        for j = 1:length(currentPRBs)
            prbIdx = double(currentPRBs(j));
            
            % -----------------------------------------------------------
            % Calculate the absolute starting subcarrier 'k' on the Carrier Grid.
            % Formula: (BWP_PRB_Index + GridOffset) * 12
            % -----------------------------------------------------------
            absPRBStartK = (prbIdx + gridOffset) * 12;
            
            % Iterate through every DMRS RE definition (row of the pattern)
            for r = 1:rePerPRB
                
                % -----------------------------------------------------------
                % Calculate linear indices for ALL Ports at this specific RE location.
                % The result matrix fills one row for every RE location 'r'.
                % -----------------------------------------------------------
                for p = 1:nPorts
                    % -----------------------------------------------------------
                    % Retrieve subcarrier offset k' for the current port.
                    % reOffset ranges: {0, ..., 11}.
                    % -----------------------------------------------------------
                    reOffset = subLocs(r, p);
                    
                    % -----------------------------------------------------------
                    % Calculate absolute subcarrier position 'k'.
                    % -----------------------------------------------------------
                    k = absPRBStartK + reOffset;
                    
                    % -----------------------------------------------------------
                    % Calculate Port Offset.
                    % Treats the 3D Grid [Subcarrier, Symbol, Port] as linear memory.
                    % Offset shifts the index to the correct "Page" for the port.
                    % -----------------------------------------------------------
                    portOffset = (p - 1) * nTotalRE_PerPort;
                    
                    % -----------------------------------------------------------
                    % Calculate Final Linear Index (1-based MATLAB index).
                    % Mapping: (Subcarrier) + (Symbol Offset) + (Port Offset)
                    %   + (k + 1)              : 1-based subcarrier index
                    %   + l * nSizeGrid * 12   : Skip full frequency grids for previous symbols
                    %   + portOffset           : Skip full grids for previous ports
                    % -----------------------------------------------------------
                    val = (k + 1) + (l * nSizeGrid * 12) + portOffset;
                    
                    % Assign value to the specific Port column
                    indices(currentRow, p) = val;
                end
                
                % Move to the next row in the result matrix
                currentRow = currentRow + 1;
            end
        end
    end
end