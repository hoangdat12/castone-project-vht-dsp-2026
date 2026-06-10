function W = generateTypeIMultiPanelPrecoder(cfg, nLayers, n_g, i1, i2)
    % Extract Codebook Configuration
    % N1, N2: Number of antenna ports in horizontal/vertical domain per panel.
    % O1, O2: Oversampling factors for DFT beams.
    N1 = cfg.CodebookConfig.N1;
    N2 = cfg.CodebookConfig.N2;
    O1 = cfg.CodebookConfig.O1;
    O2 = cfg.CodebookConfig.O2;
    nPorts = 2*n_g*N1*N2;
    codebookMode = cfg.CodebookConfig.codebookMode; % Mode 1 or Mode 2

    % Parse Input Indices (PMI)
    % Decompose the wideband index (i1) and subband index (i2) into 
    % specific beam indices and co-phasing indices.
    [i11, i12, i13, i14, i2] = computeInputs(nLayers, i1, i2, N2);

    % Validate that the indices correspond to legal 3GPP configurations
    validateInputs(codebookMode, nLayers, n_g, N1, N2, O1, O2, i11, i12, i13, i14, i2, nPorts);

    % Determine Beam Indices
    % Convert the parsed indices into DFT beam indices (l, m) for the 
    % primary beam and (lp, mp) for the secondary/orthogonal beam.
    % p, n represent co-phasing factors between polarizations and panels.
    [l, lp, m, mp, p, n] = getBeamIndices(nLayers, i11, i12, i13, i14, i2, N1, N2, O1, O2);

    % Construct Precoding Matrix Based on Rank (nLayers)
    switch nLayers
        case 1
            % Single Layer Transmission
            % Construct the fundamental oversampled DFT beam v_lm
            v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);

            if codebookMode == 1
                % Mode 1: Standard Co-phasing
                W = calcWMatrixMultiPanel(p, n, n_g, 1, 1, v_lm, nPorts);
            elseif codebookMode == 2
                % Mode 2: Enhanced Panel Co-phasing (Requires Ng=2)
                if n_g == 2
                    W = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm, nPorts);
                else 
                    warning('Invalid n_g for Codebook Mode 2. Returning zero matrix.');
                    W = zeros(nPorts, 1);
                end
            else 
                warning('Invalid Codebook Mode. Returning zero matrix.');
                W = zeros(nPorts, 1);
            end
        
        case 2
            % Dual Layer Spatial Multiplexing
            % Requires two beams: 
            % 1. v_lm (Primary)
            % 2. v_lm_p (Shifted/Orthogonal beam depending on config)
            v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);

            if codebookMode == 1
                % Calculate column for Layer 1
                w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 1, v_lm, nPorts);
                % Calculate column for Layer 2
                w_idx2 = calcWMatrixMultiPanel(p, n, n_g, 2, 1, v_lm_p, nPorts);
                
                % Combine and normalize power by 1/sqrt(Rank)
                W = (1/sqrt(2)) * [w_idx1, w_idx2]; 
            elseif codebookMode == 2
                if n_g == 2
                    w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm, nPorts);
                    w_idx2 = calcWMatrixMultiPanel(p, n, n_g, 2, 2, v_lm_p, nPorts);
                    W = (1/sqrt(2)) * [w_idx1, w_idx2];
                else 
                    warning('n_g must be 2 for Codebook Mode 2. Returning zero matrix.');
                    W = zeros(nPorts, 2);
                end
            else 
                warning('Invalid Codebook Mode. Returning zero matrix.');
                W = zeros(nPorts, 2);
            end

        case 3
            % Three Layer Spatial Multiplexing
            % Uses a combination of v_lm and v_lm_p across 3 streams.
            v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);

            if codebookMode == 1
                % Layer 1: Beam 1, Polarization A
                w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 1, v_lm, nPorts);
                % Layer 2: Beam 2, Polarization A (or shifted phase)
                w_idx2 = calcWMatrixMultiPanel(p, n, n_g, 1, 1, v_lm_p, nPorts);
                % Layer 3: Beam 1, Polarization B
                w_idx3 = calcWMatrixMultiPanel(p, n, n_g, 2, 1, v_lm, nPorts);
                
                W = (1/sqrt(3)) * [w_idx1, w_idx2, w_idx3]; % Normalization
            elseif codebookMode == 2
                if n_g == 2
                    w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm, nPorts);
                    w_idx2 = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm_p, nPorts);
                    w_idx3 = calcWMatrixMultiPanel(p, n, n_g, 2, 2, v_lm, nPorts);
                    W = (1/sqrt(3)) * [w_idx1, w_idx2, w_idx3];
                else 
                    warning('n_g must be 2 for Codebook Mode 2. Returning zero matrix.');
                    W = zeros(nPorts, 3);
                end
            else 
                warning('Invalid Codebook Mode. Returning zero matrix.');
                W = zeros(nPorts, 3);
            end

        case 4
            % Four Layer Spatial Multiplexing
            % Fully utilizes both beams on both polarizations/panels.
            v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);

            if codebookMode == 1
                % Construct 4 independent layers
                w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 1, v_lm, nPorts);
                w_idx2 = calcWMatrixMultiPanel(p, n, n_g, 1, 1, v_lm_p, nPorts);
                w_idx3 = calcWMatrixMultiPanel(p, n, n_g, 2, 1, v_lm, nPorts);
                w_idx4 = calcWMatrixMultiPanel(p, n, n_g, 2, 1, v_lm_p, nPorts);
                
                W = (1/sqrt(4)) * [w_idx1, w_idx2, w_idx3, w_idx4]; % Normalization
            elseif codebookMode == 2
                if n_g == 2
                    w_idx1 = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm, nPorts);
                    w_idx2 = calcWMatrixMultiPanel(p, n, n_g, 1, 2, v_lm_p, nPorts);
                    w_idx3 = calcWMatrixMultiPanel(p, n, n_g, 2, 2, v_lm, nPorts);
                    w_idx4 = calcWMatrixMultiPanel(p, n, n_g, 2, 2, v_lm_p, nPorts);
                    W = (1/sqrt(4)) * [w_idx1, w_idx2, w_idx3, w_idx4];
                else 
                    warning('n_g must be 2 for Codebook Mode 2. Returning zero matrix.');
                    W = zeros(nPorts, 4);
                end
            else 
                warning('Invalid Codebook Mode. Returning zero matrix.');
                W = zeros(nPorts, 4);
            end

        otherwise
            % Error handling for unsupported Ranks (e.g., > 4)
            warning('Unsupported number of layers (%d). Returning empty matrix.', nLayers);
            W = [];
    end
end

%% --- HELPER FUNCTIONS ---

function validateInputs(codebookMode, nLayers, n_g, N1, N2, O1, O2, i11, i12, i13, i14, i2, nPorts)
    validConfig = false;
    switch nPorts
        case 8
            if isequal([n_g, N1, N2], [2, 2, 1]) && isequal([O1, O2], [4, 1]), validConfig = true; end
        case 16
            configs = [2,4,1; 4,2,1; 2,2,2];
            oversampling = [4,1; 4,1; 4,4];
            for k = 1:size(configs, 1)
                if isequal([n_g, N1, N2], configs(k,:)) && isequal([O1, O2], oversampling(k,:)), validConfig = true; break; end
            end
        case 32
            configs = [2,8,1; 4,4,1; 2,4,2; 4,2,2];
            oversampling = [4,1; 4,1; 4,4; 4,4];
            for k = 1:size(configs, 1)
                if isequal([n_g, N1, N2], configs(k,:)) && isequal([O1, O2], oversampling(k,:)), validConfig = true; break; end
            end
    end
    if ~validConfig
        error('Invalid combination of nPorts (%d), Ng (%d), N1 (%d), N2 (%d), O1 (%d), O2 (%d).', ...
            nPorts, n_g, N1, N2, O1, O2);
    end

    % 2. Validate codebookMode and Ng relationship
    if codebookMode == 2 && n_g ~= 2
        error('codebookMode 2 is only supported for Ng = 2 panels.');
    end
    if ~ismember(codebookMode, [1, 2])
        error('codebookMode must be 1 or 2.');
    end

    % 3. Validate nLayers (RI)
    if ~ismember(nLayers, [1, 2, 3, 4])
        error('nLayers (Rank) must be between 1 and 4.');
    end

    % 4. Validate i1,1 and i1,2 ranges
    if i11 < 0 || i11 >= N1*O1
        error('i11 must be in range [0, N1*O1 - 1] = [0, %d].', N1*O1 - 1);
    end
    if i12 < 0 || i12 >= N2*O2
        error('i12 must be in range [0, N2*O2 - 1] = [0, %d].', N2*O2 - 1);
    end

    % 5. Validate i1,3 for Rank 2, 3, 4
    if nLayers > 1
        % For nLayers=2, uses Table 5.2.2.2.1-3. For 3&4, uses Table 5.2.2.2.2-2
        % Check max value of i1,3 based on (N1, N2) from Table 5.2.2.2.2-2
        max_i13 = 0;
        if isequal([N1, N2], [2, 1]), max_i13 = 0;
        elseif isequal([N1, N2], [4, 1]), max_i13 = 2;
        elseif isequal([N1, N2], [8, 1]), max_i13 = 3;
        elseif isequal([N1, N2], [2, 2]), max_i13 = 2;
        elseif isequal([N1, N2], [4, 2]), max_i13 = 3;
        end
        if i13 < 0 || i13 > max_i13
            error('i13 is out of bounds for the current antenna configuration (N1=%d, N2=%d).', N1, N2);
        end
    end

    % 6. Validate i1,4 and i2 based on codebookMode
    if codebookMode == 1
        % i1,4 is a vector of size Ng-1
        if length(i14) ~= (n_g - 1)
            error('For codebookMode 1, i14 must be a vector of size Ng-1 = %d.', n_g - 1);
        end
        if any(i14 < 0 | i14 > 3)
            error('All elements of i14 must be in {0, 1, 2, 3}.');
        end
        % i2 is a single value 0 or 1
        if ~ismember(i2, [0, 1])
            error('For codebookMode 1, i2 must be 0 or 1.');
        end
    else % codebookMode == 2
        % i1,4 is a vector [i141, i142]
        if length(i14) ~= 2
            error('For codebookMode 2, i14 must be a vector [i141, i142].');
        end
        % i2 is a vector [i20, i21, i22]
        if length(i2) ~= 3
            error('For codebookMode 2, i2 must be a vector [i20, i21, i22].');
        end
    end
end

function [i11, i12, i13, i14, i2] = computeInputs(nLayers, i1, i2, N2)
    % Extract i1,1 (first PMI index)
    % According to Tables 5.2.2.2.2-3 through 5.2.2.2.2-6, i1,1 is always 
    % present regardless of the rank or configuration.
    i11 = i1{1};

    if N2 == 1
        % According to Section 5.2.2.2.2: "UE shall only use i1,2 = 0 and shall not 
        % report i1,2 if the value of N2 is 1."
        i12 = 0;
    else 
        % Otherwise, retrieve i1,2 normally.
        i12 = i1{2};
    end

    if nLayers == 1
        % Refer to Table 5.2.2.2.2-3 (Codebook for 1-layer CSI reporting):
        % For Rank 1 (v=1), the vector i1 consists only of [i1,1, i1,2, i1,4].
        % The index i1,3 is not defined/used for 1-layer reporting.
        i13 = 0;
    else 
        % Refer to Tables 5.2.2.2.2-4, 5.2.2.2.2-5, and 5.2.2.2.2-6 (Rank 2, 3, 4):
        % For Rank > 1, i1,3 is used to map to k1 and k2 (as per Table 5.2.2.2.2-2).
        i13 = i1{3};
    end

    % Extract i1,4 (co-phasing coefficient index across panels)
    % i1,4 is present for all ranks (Tables 5.2.2.2.2-3 to 5.2.2.2.2-6).
    % 4th element always maps to i1,4.
    i14 = i1{4};
end

function [l, lp, m, mp, p, n] = getBeamIndices(nLayers, i11, i12, i13, i14, i2, N1, N2, O1, O2)
    % Initialize default values to 0 to prevent "undefined variable" errors
    [l, lp, m, mp, p, n] = deal(0); 

    % Calculate beam offsets k1 and k2 based on 3GPP Table 5.2.2.2.2-2
    % (Note: This maps i1,3 to k1 and k2 for Rank 3-4, and Table 5.2.2.2.1-3 for Rank 2)
    [k1, k2] = getK1K2(i13, N1, N2, O1, O2); 

    if nLayers == 1
        % Refer to Table 5.2.2.2.2-3 (Codebook for 1-layer CSI reporting).
        % For Rank 1, the precoder W is constructed using a single beam v_{l,m}.
        % l corresponds to i1,1 (0...N1*O1-1).
        % m corresponds to i1,2 (0...N2*O2-1).
        l = i11; 
        m = i12; 
        
        % p corresponds to i1,4 (panel co-phasing index).
        % n corresponds to i2 (sub-band co-phasing index).
        p = i14; 
        n = i2;
        % lp and mp remain 0 as default (no shifted beams for Rank 1)
        
    elseif ismember(nLayers, [2, 3, 4])
        % Refer to Tables 5.2.2.2.2-4 (Rank 2), 5.2.2.2.2-5 (Rank 3), and 5.2.2.2.2-6 (Rank 4).
        % These tables define the precoder using base indices and shifted indices.
        
        % Base beam indices l and m derived directly from i1,1 and i1,2.
        l = i11; 
        m = i12; 
        
        % Shifted beam indices l' (lp) and m' (mp).
        % As per the "i1,1 + k1" and "i1,2 + k2" definitions in the referenced tables,
        % the second beam v_{l',m'} is offset by k1 (horizontal) and k2 (vertical).
        lp = l + k1; % Horizontal beam shift (l')
        mp = m + k2; % Vertical beam shift (m')
        
        % Panel and Co-phasing indices
        p = i14; 
        n = i2; 
    else
        warning('Unsupported nLayers. Defaulting to 0.');
    end
end

function [k1, k2] = getK1K2(i13, N1, N2, O1, O2)
    % Default offset is zero
    k1 = 0;
    k2 = 0;

    % Mapping logic based on antenna port layout (N1, N2)
    % See Table 5.2.2.2.2-2: Mapping of i1,3 to k1 and k2 

    if N1 == 2 && N2 == 1
        % Column 1 of Table 5.2.2.2.2-2
        % Only index 0 is defined for this configuration
        if i13 == 0
            k1 = O1; k2 = 0;
        end
        
    elseif N1 == 4 && N2 == 1
        % Column 2 of Table 5.2.2.2.2-2
        switch i13
            case 0; k1 = O1;   k2 = 0;
            case 1; k1 = 2*O1; k2 = 0;
            case 2; k1 = 3*O1; k2 = 0;
        end
        
    elseif N1 == 8 && N2 == 1
        % Column 3 of Table 5.2.2.2.2-2
        switch i13
            case 0; k1 = O1;   k2 = 0;
            case 1; k1 = 2*O1; k2 = 0;
            case 2; k1 = 3*O1; k2 = 0;
            case 3; k1 = 4*O1; k2 = 0;
        end
        
    elseif N1 == 2 && N2 == 2
        % Column 4 of Table 5.2.2.2.2-2
        switch i13
            case 0; k1 = O1; k2 = 0;
            case 1; k1 = 0;  k2 = O2;
            case 2; k1 = O1; k2 = O2;
        end
        
    elseif N1 == 4 && N2 == 2
        % Column 5 of Table 5.2.2.2.2-2
        switch i13
            case 0; k1 = O1;   k2 = 0;
            case 1; k1 = 0;    k2 = O2;
            case 2; k1 = O1;   k2 = O2;
            case 3; k1 = 2*O1; k2 = 0;
        end
    end
end

function v = computeBeam(l, m, N1, N2, O1, O2, phaseFactor)
    % Calculates the quantity v_{l,m} used to define codebook elements.
    
    % Calculate the vertical beam vector u_m (or u_n2)
    if N2 == 1
        % If N2=1, u_m is a scalar 1.
        u_n2 = 1;
    else 
        % If N2 > 1, u_m is a vector: [1, e^{j2*pi*m/...}, ..., e^{j2*pi*m(N2-1)/...}]^T
        n2 = (0:N2-1).';
        u_n2 = exp(1j * phaseFactor * pi * m * n2 / (O2 * N2));
    end
    
    % Calculate the horizontal phase shift terms associated with index l.
    n1 = (0:N1-1).';
    u_n1 = exp(1j * phaseFactor * pi * l * n1 / (O1 * N1));
  
    % Construct v_{l,m} using Kronecker product.
    v = kron(u_n1, u_n2);
    
    % Ensure the result is a column vector
    v = v(:);
end

function phi_n = computePhiN(n)
    phi_n = exp(1j*pi*n/2);
end

function phi_p = computePhiP(p)
    phi_p = exp(1j*pi*p/2);
end

function a_p = computeAP(p)
    a_p = exp(1j*pi/4)*exp(1j*pi*p/2);
end

function b_n = computeBN(n)
    b_n = exp(-1j*pi/4)*exp(1j*pi*n/2);
end

function W = calcWMatrixMultiPanel(p, n, Ng, idxRank, rank, vLm, nPorts)
    % Power normalization factor based on the total number of CSI-RS ports
    norm_factors = 1/(sqrt(nPorts)); 

    if Ng == 2
        if rank == 1
            % Based on W^{x, 2, 1} formulas
            phi_p1 = computePhiP(p(1)); 
            phi_n  = computePhiN(n(1)); 
            
            if idxRank == 1
                W = norm_factors * [vLm; phi_n*vLm; phi_p1*vLm; phi_n*phi_p1*vLm];
            else
                % W^{2, 2, 1} uses -phi_n
                W = norm_factors * [vLm; -phi_n*vLm; phi_p1*vLm; -phi_n*phi_p1*vLm];
            end
            
        elseif rank == 2
            % Based on W^{x, 2, 2} formulas (utilizing a_p and b_n)
            phi_n0 = computePhiN(n(1)); 
            a_p1 = computeAP(p(1));
            a_p2 = computeAP(p(2));
            b_n1 = computeBN(n(2));
            b_n2 = computeBN(n(3));

            if idxRank == 1
                W = norm_factors * [vLm; phi_n0*vLm; a_p1*b_n1*vLm; a_p2*b_n2*vLm];
            else
                % W^{2, 2, 2} uses negative signs for certain polarization components
                W = norm_factors * [vLm; -phi_n0*vLm; a_p1*b_n1*vLm; -a_p2*b_n2*vLm];
            end
        end

    elseif Ng == 4
        % Based on W^{x, 4, 1} formulas
        phi_n = computePhiN(n(1)); 
        phi_p1 = computePhiP(p(1));
        phi_p2 = computePhiP(p(2));
        phi_p3 = computePhiP(p(3));

        if idxRank == 1
            W = norm_factors * [vLm; ...
                                phi_n*vLm; ...
                                phi_p1*vLm; phi_n*phi_p1*vLm; ...
                                phi_p2*vLm; phi_n*phi_p2*vLm; ...
                                phi_p3*vLm; phi_n*phi_p3*vLm];
        else
            % Alternating signs for the second layer in multi-panel
            W = norm_factors * [vLm; ...
                                -phi_n*vLm; ...
                                phi_p1*vLm; -phi_n*phi_p1*vLm; ...
                                phi_p2*vLm; -phi_n*phi_p2*vLm; ...
                                phi_p3*vLm; -phi_n*phi_p3*vLm];
        end
    end
end