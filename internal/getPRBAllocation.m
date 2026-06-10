function prbset = getPRBAllocation(pdsch, carrier)
% -----------------------------------------------------------
% INTERLEAVERVRBTOPRB: Performs VRB-to-PRB mapping for 5G NR PDSCH
% -----------------------------------------------------------
% This function maps Virtual Resource Blocks (VRB) to Physical Resource Blocks (PRB).
% Standard Reference: 3GPP TS 38.211 Section 6.3.1.5
% -----------------------------------------------------------

    % -----------------------------------------------------------
    % 1. Extract Basic Parameters
    % -----------------------------------------------------------
    NSizeBWP = double(pdsch.NSizeBWP);
    NStartBWP = double(pdsch.NStartBWP);
    prbset = double(pdsch.PRBSet(:)'); % Ensure row vector format
    
    % -----------------------------------------------------------
    % 2. Determine Reference Point (rbrefpoint)
    % The interleaving bundle grid is aligned to a reference point.
    % If DMRSReferencePoint is 'CRB0', alignment starts from Common Resource Block 0.
    % Otherwise, it aligns to the start of the BWP (Point A implicit).
    % -----------------------------------------------------------
    if isfield(pdsch, 'DMRS') && isfield(pdsch.DMRS, 'DMRSReferencePoint') && ...
            strcmp(pdsch.DMRS.DMRSReferencePoint, 'CRB0')
        if isempty(NStartBWP)
            rbrefpoint = double(carrier.NStartGrid);
        else
            rbrefpoint = double(NStartBWP(1));
        end
    else
        rbrefpoint = 0;
    end

    % -----------------------------------------------------------
    % 3. Check Interleaving Condition
    % Interleaving is only applied if:
    %   + VRBToPRBInterleaving is TRUE.
    %   + Resource allocation type is 'VRB'.
    % -----------------------------------------------------------
    if pdsch.VRBToPRBInterleaving && strcmpi(pdsch.PRBSetType, 'VRB')
        % disp("Debug: Running Interleaving Logic...");
        
        % Bundle Size L = {2, 4}
        L = double(pdsch.VRBBundleSize); 
        
        % -----------------------------------------------------------
        % A. INTERLEAVER LOGIC (Create Map for Entire BWP)
        % -----------------------------------------------------------
        
        % Calculate offset to align bundles with CRB0 (or ref point)
        rboffsetModL = mod(rbrefpoint, L);
        
        % Total number of bundles required to cover the BWP
        nBundle = ceil((NSizeBWP + rboffsetModL) / L);
        
        if nBundle > 1
            % -----------------------------------------------------------
            % Calculate size of each Bundle
            %   + First bundle: May be partial due to offset.
            %   + Middle bundles: Always size L.
            %   + Last bundle: Remainder of the BWP.
            % -----------------------------------------------------------
            numRBinBundle = zeros(1, nBundle);
            numRBinBundle(1) = L - rboffsetModL;
            numRBinBundle(end) = mod(rbrefpoint + NSizeBWP, L);
            
            if numRBinBundle(end) == 0, numRBinBundle(end) = L; end
            if nBundle > 2, numRBinBundle(2:end-1) = L; end
            
            % -----------------------------------------------------------
            % Create Block Interleaver (Row-Column Interleaver)
            % Rows R = 2 (Fixed by standard).
            % Columns C = TotalBundles / R.
            % -----------------------------------------------------------
            R = 2;
            C = floor(nBundle / R);
            r = (0:R-1)'; 
            c = 0:C-1;
            
            % Generate matrix indices: Read in rows, write out columns? 
            % (Standard specific interleaving pattern f(j))
            prbbInd = repmat(r*C, 1, C) + repmat(c, R, 1);
            prbbInd = prbbInd(:)'; 
            
            % -----------------------------------------------------------
            % Handle odd number of bundles (Last bundle logic)
            % The last bundle is often left out of the R x C matrix and appended.
            % -----------------------------------------------------------
            if numel(prbbInd) ~= nBundle
                prbbInd = [prbbInd, nBundle-1];
            else
                prbbInd(nBundle) = nBundle-1;
            end
            
            % -----------------------------------------------------------
            % Calculate Starting PRB Index for each Bundle
            % Formula attempts to reconstruct start position based on permuted indices.
            % -----------------------------------------------------------
            activeBundles = 2:length(prbbInd)-1;
            prbInd = (prbbInd(activeBundles) .* numRBinBundle(activeBundles)) - rboffsetModL;
            
            % -----------------------------------------------------------
            % Create Full BWP Map (mapIndices)
            % This vector maps: VRB Index -> PRB Index
            % -----------------------------------------------------------
            mapIndices = NaN(1, NSizeBWP);
            
            % Bundle 0 (First partial bundle)
            mapIndices(1:numRBinBundle(1)) = 0 : numRBinBundle(1)-1;
            
            % Middle Bundles (Interleaved)
            if ~isempty(prbInd)
                % Create a matrix to fill all middle bundle REs at once
                tmp = repmat(prbInd, L, 1) + repmat((0:L-1)', 1, numel(prbInd));
                
                idxStart = 1 + numRBinBundle(1);
                idxEnd = NSizeBWP - numRBinBundle(end);
                
                % Ensure fill length matches available slots
                lenFill = idxEnd - idxStart + 1;
                tmpFill = tmp(:)';
                mapIndices(idxStart:idxEnd) = tmpFill(1:lenFill);
            end
            
            % Last Bundle
            idxLastStart = NSizeBWP - numRBinBundle(end) + 1;
            if idxLastStart <= NSizeBWP
                 % Last bundle usually maps to remaining available PRBs.
                 % Logic: Find PRBs not yet assigned in mapIndices.
                 usedPRBs = mapIndices(~isnan(mapIndices));
                 allPRBs = 0:NSizeBWP-1;
                 remaining = setdiff(allPRBs, usedPRBs); % Automatically sorted
                 mapIndices(idxLastStart:end) = remaining;
            end
        else
            % BWP is too small (Only 1 bundle) -> No interleaving
            mapIndices = 0:NSizeBWP-1;
        end

        % -----------------------------------------------------------
        % B. MAPPING LOGIC
        % -----------------------------------------------------------
        if ~isempty(prbset)
            % input 'prbset' contains VRB Indices (e.g., [0, 1, 2])
            % 'mapIndices' acts as the Look-Up Table: 
            %   Index (k+1) contains the PRB for VRB k.
            
            % Filter invalid VRBs that exceed BWP size
            validVRBs = prbset(prbset < NSizeBWP);
            
            % Direct Mapping
            % +1 accounts for MATLAB 1-based indexing vs 0-based VRB
            prbset = mapIndices(validVRBs + 1);
            
            % NOTE: Do NOT sort here.
            % Retain VRB order to ensure PDSCH mapping follows VRB sequence.
        else
            prbset = [];
        end
            
    else
        % -----------------------------------------------------------
        % Non-Interleaved or Pre-defined PRB Case
        % -----------------------------------------------------------
        % If Type='VRB' but Interleaving is OFF:
        %   VRB i maps directly to PRB i.
        %   Sort ensures resources are contiguous if input was scrambled.
        % -----------------------------------------------------------
        if strcmpi(pdsch.PRBSetType, 'VRB')
             prbset = sort(prbset); 
        end
        % If Type='PRB', 'prbset' is treated as physical indices given by user.
    end
end