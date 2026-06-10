function dmrs_values = genDMRS(carrier, pdsch, enabledR16)
% -----------------------------------------------------------
% GENDMRS: Generates DMRS complex symbols (Type 1 & Type 2)
% -----------------------------------------------------------
    if nargin < 3
        enabledR16 = false;
    end

    [dmrssymbols, ~] = lookupDMRSTable(carrier, pdsch);
    
    if isempty(dmrssymbols)
        dmrs_values = [];
        return;
    end

    c_init_list = generateCInit(pdsch.DMRS, carrier, dmrssymbols, enabledR16);

    if pdsch.DMRS.DMRSConfigurationType == 2
        N_DMRS_SC = 4;
    else
        N_DMRS_SC = 6; 
    end

    PRBSet = pdsch.PRBSet;
    numRBs = length(PRBSet);
    startRB_in_BWP = PRBSet(1);
    
    rbrefpoint = 0; 
    if strcmpi(pdsch.DMRS.DMRSReferencePoint, 'CRB0')
        rbrefpoint = double(carrier.NStartGrid);
    end
    
    absolute_startRB = rbrefpoint + startRB_in_BWP;

    numSubcarriersPerSymbol = N_DMRS_SC * numRBs;
    total_elements = length(dmrssymbols) * numSubcarriersPerSymbol;
    
    dmrs_values = complex(zeros(total_elements, pdsch.NumLayers));
    
    % Extract OCC Weights matrices from pdsch.DMRS structure
    fmaskAllPorts = pdsch.DMRS.FrequencyWeights;
    tmaskAllPorts = pdsch.DMRS.TimeWeights;
    
    % scale_factor = sqrt(pdsch.DMRS.NumCDMGroupsWithoutData);
    CDM_without_data = pdsch.DMRS.NumCDMGroupsWithoutData;
    switch CDM_without_data
        case 1
            beta_dmrs = 0;
        case 2
            beta_dmrs = -3;
        case 3
            beta_dmrs = -4.77;
        otherwise
            beta_dmrs = 0;
    end
    scale_factor = 10^(-beta_dmrs/20);

    for i = 1:length(dmrssymbols)
        c_init = c_init_list(i);
        
        offset_bits = 2 * N_DMRS_SC * absolute_startRB;
        needed_bits = 2 * N_DMRS_SC * numRBs;
        total_bits_to_gen = offset_bits + needed_bits;
        
        full_seq_bits = GoldSequence(c_init, total_bits_to_gen);
        useful_bits = full_seq_bits(offset_bits + 1 : end);
        
        bit_pairs = reshape(useful_bits, 2, []); 
        real_part = (1 - 2 * bit_pairs(1, :)) / sqrt(2);
        imag_part = (1 - 2 * bit_pairs(2, :)) / sqrt(2);
        
        complex_symbol_vector = complex(real_part, imag_part).';
        
        startIndex = (i - 1) * numSubcarriersPerSymbol + 1;
        endIndex = i * numSubcarriersPerSymbol;
        
        % -----------------------------------------------------------
        % APPLY OCC: Frequency & Time Weights per Layer
        % -----------------------------------------------------------
        
        % 1. Determine l' (time index for TimeWeight)
        % l_prime = 1 if this is the 2nd symbol in a double-symbol pair, else 0
        l_prime = 0;
        if i > 1 && (dmrssymbols(i) == dmrssymbols(i-1) + 1)
            l_prime = 1;
        end
        
        % 2. Iterate over Layers to multiply Weights and assign
        for layerIdx = 1:pdsch.NumLayers
            % Extract time-domain weight for the current symbol (1-based index)
            wt = tmaskAllPorts(l_prime + 1, layerIdx);
            
            % Extract frequency-domain weight for the current layer
            wf = fmaskAllPorts(:, layerIdx);
            
            % Replicate wf sequence across the allocated bandwidth
            wf_pattern = repmat(wf, numSubcarriersPerSymbol / length(wf), 1);
            
            % Multiply base sequence by OCC and store in respective layer column
            dmrs_values(startIndex:endIndex, layerIdx) = complex_symbol_vector .* wf_pattern .* wt .* scale_factor;
            %  dmrs_values(startIndex:endIndex, layerIdx) = complex_symbol_vector .* wf_pattern .* wt;
        end
    end
end

function c_init = generateCInit(dmrs, carrier, dmrssymbols, enabledR16)
% -----------------------------------------------------------
% GENERATECINIT: Calculates initialization seed for Gold Sequence
% Formula: c_init = (2^17 * (14*ns + l + 1) * (2*N_ID + 1) + 2*N_ID + n_SCID) mod 2^31
% -----------------------------------------------------------

    % Extract Basic Parameters
    symbperslot = carrier.SymbolsPerSlot;
    nslot = mod(double(carrier.NSlot), carrier.SlotsPerFrame);
    
    % -----------------------------------------------------------
    % Determine Scrambling ID (N_ID)
    % Uses either Cell ID or a specific configured list (NIDNSCID)
    % -----------------------------------------------------------
    if isempty(dmrs.NIDNSCID)
        N_ID = carrier.NCellID;
    else
        % Safe Indexing: Ensure we don't exceed the array bounds of NIDNSCID
        idx = min(dmrs.NSCID + 1, length(dmrs.NIDNSCID));
        N_ID = dmrs.NIDNSCID(idx);
    end

    % -----------------------------------------------------------
    % Determine n_SCID & Lambda (CDM Group Parameter)
    % -----------------------------------------------------------
    raw_nSCID = dmrs.NSCID;
    lambda = dmrs.CDMGroups(1); 
    
    % Special handling for Rel-16 w/ Lambda=1
    if enabledR16 && (lambda == 1)
        n_SCID = 1 - raw_nSCID;
    else
        n_SCID = raw_nSCID;
    end

    % -----------------------------------------------------------
    % Calculate c_init for each symbol
    % -----------------------------------------------------------
    c_init = zeros(1, length(dmrssymbols));

    for i = 1:length(dmrssymbols)
        l = dmrssymbols(i); 
        
        % Part A: Time Domain component (Slot + Symbol)
        A = (symbperslot * nslot) + l + 1;
        
        % Part B: ID component
        B = 2 * N_ID + 1;
        
        % Part Lambda: Additional term based on CDM Group
        Term_Lambda = 2^17 * floor(lambda / 2);

        % Part C: ID + n_SCID component
        C = 2 * N_ID + n_SCID;
        
        % Combine: (2^17 * A * B) + Term_Lambda + C
        val = (2^17 * A * B) + Term_Lambda + C;
        
        c_init(i) = mod(val, 2^31);
    end
end

function c = GoldSequence(c_init, N)
% -----------------------------------------------------------
% GOLDSEQUENCE: Generates length-31 Pseudo-Random Sequence
% Standard: 3GPP TS 38.211 Section 5.2.1
% -----------------------------------------------------------

    x1 = zeros(1, 31); 
    x2 = zeros(1, 31);
    x1(1) = 1;

    % -----------------------------------------------------------
    % Initialize x2 with c_init
    % Converted to binary array, LSB first
    % -----------------------------------------------------------
    for i = 1:31
        x2(i) = bitget(c_init, i);
    end

    % -----------------------------------------------------------
    % Define Output Length
    % We generate N + 1600 bits because the first 1600 (Nc) 
    % are discarded to avoid transient states.
    % -----------------------------------------------------------
    L = N + 1600;
    seq = zeros(L,1);

    % -----------------------------------------------------------
    % Sequence Generation Loop
    % Polynomials:
    %   x1: D^31 + D^3 + 1
    %   x2: D^31 + D^3 + D^2 + D + 1
    % -----------------------------------------------------------
    for n = 1:L
        % Output Calculation: c(n) = (x1(n+Nc) + x2(n+Nc)) mod 2
        seq(n) = xor(x1(1), x2(1));

        % Feedback Calculation
        new_x1 = xor(x1(1), x1(4));
        new_x2 = xor(xor(x2(4), x2(3)), xor(x2(2), x2(1)));

        % Shift Registers (Standard MATLAB implementation of LFSR)
        x1 = [x1(2:end), new_x1];
        x2 = [x2(2:end), new_x2];
    end

    % -----------------------------------------------------------
    % Final Output
    % Discard the initialization phase (Nc = 1600)
    % -----------------------------------------------------------
    c = logical(seq(1601:end));
end