function W = generateTypeISinglePanelPrecoder(cfg, nLayers, i1, i2)
    % Get input parameters
    N1 = cfg.CodebookConfig.N1;
    N2 = cfg.CodebookConfig.N2;
    O1 = cfg.CodebookConfig.O1;
    O2 = cfg.CodebookConfig.O2;
    nPorts = 2*N1*N2;
    codebookMode = cfg.CodebookConfig.codebookMode;

    validateInputs(nPorts, N1, N2, O1, O2);

    % Handling for 2 Antenna Ports (Ref: TS 38.214 Table 5.2.2.2.1-1)
    if nPorts == 2
        % For 2 ports, the codebook index is typically passed in i2 (0-3 for rank 1, 0-1 for rank 2).
        % i1 is not used for 2 ports.
        codebookIndex = i2; 

        if nLayers == 1
            % Rank 1 (1 Layer): Indices 0, 1, 2, 3 
            % W = (1/sqrt(2)) * [1; phi] where phi = exp(j*pi*n/2)
            
            if codebookIndex < 0 || codebookIndex > 3
                error('Error: Codebook index for 2-port Rank 1 must be between 0 and 3.');
            end

            % Calculate phi based on the table rows:
            % Index 0: [1; 1]   -> phi = 1
            % Index 1: [1; j]   -> phi = j
            % Index 2: [1; -1]  -> phi = -1
            % Index 3: [1; -j]  -> phi = -j
            phi = exp(1j * pi * codebookIndex / 2);

            W = (1/sqrt(2)) * [1; phi];

        elseif nLayers == 2
            % Rank 2 (2 Layers): Indices 0, 1 
            % W = (1/2) * [1, 1; phi, -phi]
            
            if codebookIndex < 0 || codebookIndex > 1
                error('Error: Codebook index for 2-port Rank 2 must be 0 or 1.');
            end

            % Calculate phi based on the table:
            % Index 0: 1/2 * [1, 1; 1, -1]  -> phi = 1
            % Index 1: 1/2 * [1, 1; j, -j]  -> phi = j
            phi = exp(1j * pi * codebookIndex / 2);

            W = (1/2) * [1, 1; phi, -phi];

        else
            warning("Invalid RI! Only Rank 1 and Rank 2 are supported for 2 antenna ports.");
            W = [];
        end
        return;
    end

    % Format input
    [i11, i12, i13, i2] = computeInputs(i1, i2, N2, nLayers);

    phiSet = [1, 1j, -1, -1j];

    % Get beam indices
    [l, m, lp, mp, lpp, mpp, lppp, mppp, p, n] = getBeamIndices(codebookMode, nPorts, nLayers, i11, i12, i13, i2, N1, N2, O1, O2);

    % Compute phi & theta
    phi_n = phiSet(n+1);
    theta_p = exp(1j * pi * p / 4);

    switch nLayers
        case 1
            v_lm = computeBeam(l, m, N1, N2, O1, O2, 2);

            W = (1/sqrt(nPorts)) * [v_lm; ...
                                    phi_n * v_lm];
            
        case 2
            v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);

            W = (1/sqrt(2*nPorts)) * [v_lm,       v_lm_p; ...
                                      phi_n*v_lm, -phi_n*v_lm_p];
            
        case 3
            if nPorts < 16
                v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
                v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);
                
                W = (1/sqrt(3*nPorts)) * [v_lm,       v_lm_p,       v_lm; ...
                                          phi_n*v_lm, phi_n*v_lm_p, -phi_n*v_lm];
            else
                v_lm   = computeBeam(l, m, N1/2, N2, O1, O2, 2); 
                
                W = (1/sqrt(3*nPorts)) * [v_lm,                 v_lm,                   v_lm; ...
                                          theta_p*v_lm,         -theta_p*v_lm,          theta_p*v_lm; ...
                                          phi_n*v_lm,           phi_n*v_lm,             -phi_n*v_lm; ...
                                          phi_n*theta_p*v_lm,    -phi_n*theta_p*v_lm,    -phi_n*theta_p*v_lm];
            end

        case 4
            if nPorts < 16
                v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
                v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);

                W = (1/sqrt(4*nPorts)) * [v_lm,       v_lm_p,       v_lm        , v_lm_p; ...
                                          phi_n*v_lm, phi_n*v_lm_p, -phi_n*v_lm,  -phi_n*v_lm_p];
            else
                v_lm   = computeBeam(l, m, N1/2, N2, O1, O2, 2); 

                W = (1/sqrt(4*nPorts)) * [v_lm,                 v_lm,                   v_lm,                   v_lm; ...
                                          theta_p*v_lm,         -theta_p*v_lm,          theta_p*v_lm,           -theta_p*v_lm; ...
                                          phi_n*v_lm,           phi_n*v_lm,             -phi_n*v_lm,            -phi_n*v_lm; ...
                                          phi_n*theta_p*v_lm,    -phi_n*theta_p*v_lm,   -phi_n*theta_p*v_lm,    phi_n*theta_p*v_lm];
            end
        
        case 5
            v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);
            v_lm_pp = computeBeam(lpp, mpp, N1, N2, O1, O2, 2);

            W = (1/sqrt(5*nPorts)) * [v_lm,       v_lm,         v_lm_p,         v_lm_p,       v_lm_pp; ...
                                      phi_n*v_lm, -phi_n*v_lm,  v_lm_p,         -v_lm_p,      v_lm_pp];

        case 6
            v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);
            v_lm_pp = computeBeam(lpp, mpp, N1, N2, O1, O2, 2);

            W = (1/sqrt(6*nPorts)) * [v_lm,       v_lm,         v_lm_p,         v_lm_p,         v_lm_pp,      v_lm_pp; ...
                                      phi_n*v_lm, -phi_n*v_lm,  phi_n*v_lm_p,   -phi_n*v_lm_p,  v_lm_pp,      -v_lm_pp];
        case 7
            v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);
            v_lm_pp = computeBeam(lpp, mpp, N1, N2, O1, O2, 2);
            v_lm_ppp = computeBeam(lppp, mppp, N1, N2, O1, O2, 2);

            W = (1/sqrt(7*nPorts)) * [v_lm,       v_lm,         v_lm_p,         v_lm_pp,        v_lm_pp,      v_lm_ppp,     v_lm_ppp; ...
                                      phi_n*v_lm, -phi_n*v_lm,  phi_n*v_lm_p,   v_lm_pp,        -v_lm_pp,     v_lm_ppp,     -v_lm_ppp];
        case 8
            v_lm   = computeBeam(l, m, N1, N2, O1, O2, 2);
            v_lm_p = computeBeam(lp, mp, N1, N2, O1, O2, 2);
            v_lm_pp = computeBeam(lpp, mpp, N1, N2, O1, O2, 2);
            v_lm_ppp = computeBeam(lppp, mppp, N1, N2, O1, O2, 2);

            W = (1/sqrt(8*nPorts)) * [v_lm,       v_lm,         v_lm_p,         v_lm_p       v_lm_pp,        v_lm_pp,      v_lm_ppp,     v_lm_ppp; ...
                                      phi_n*v_lm, -phi_n*v_lm,  phi_n*v_lm_p,   -phi_n*v_lm_p  v_lm_pp,        -v_lm_pp,     v_lm_ppp,     -v_lm_ppp];
    end
end

%% --- HELPER FUNCTION ---

function validateInputs(NPorts, N1, N2, O1, O2)
    % validateInputs checks if the provided Channel State Information (CSI) 
    % parameters form a valid configuration supported by the 3GPP standard.
    %
    % Parameters:
    %   NPorts - Number of CSI-RS antenna ports
    %   N1, N2 - Number of antenna ports in the first and second dimensions 
    %   O1, O2 - Oversampling factors corresponding to N1 and N2

    % Retrieve the list of valid CSI configurations
    cfg = getValidCSIConfig();

    isValid = false;

    % Iterate through the configuration database to find a match
    for k = 1:length(cfg)
        if cfg(k).NPorts == NPorts && ...
           cfg(k).N1 == N1 && cfg(k).N2 == N2 && ...
           cfg(k).O1 == O1 && cfg(k).O2 == O2
            isValid = true;
            break; % Valid configuration found, exit the loop
        end
    end

    % If no matching configuration is found, throw an error
    if ~isValid
        error(['Invalid CSI configuration!\n', ...
               'NPorts = %d, (N1,N2) = (%d,%d), (O1,O2) = (%d,%d)\n', ...
               'Check 3GPP TS 38.214 Table 5.2.2.2.1-2.'], ...
               NPorts, N1, N2, O1, O2);
    end
end

function cfg = getValidCSIConfig()
    % This function returns a structure array of supported configurations.
    % Data is based on Table 5.2.2.2.1-2: Supported configurations of (N1,N2) and (O1,O2)
    % from 3GPP TS 38.214
    %
    % Note: The number of CSI-RS ports is calculated as P_CSI-RS = 2 * N1 * N2.

    cfg = struct('NPorts', {}, 'N1', {}, 'N2', {}, 'O1', {}, 'O2', {});
    
    % --- 4 Antenna Ports ---
    % Standard configuration for 4 ports 
    cfg(end+1) = struct('NPorts', 4, 'N1', 2, 'N2', 1, 'O1', 4, 'O2', 1);
    % Additional configuration (supplemented)
    cfg(end+1) = struct('NPorts', 4, 'N1', 2, 'N2', 2, 'O1', 4, 'O2', 4); 

    % --- 8 Antenna Ports ---
    % Additional configuration (supplemented)
    cfg(end+1) = struct('NPorts', 8, 'N1', 4, 'N2', 1, 'O1', 4, 'O2', 1); 
    % Standard configuration for 8 ports 
    cfg(end+1) = struct('NPorts', 8, 'N1', 2, 'N2', 2, 'O1', 4, 'O2', 4);

    % --- 12 Antenna Ports ---
    % Configurations supported for 12 ports 
    cfg(end+1) = struct('NPorts', 12, 'N1', 3, 'N2', 2, 'O1', 4, 'O2', 4);
    cfg(end+1) = struct('NPorts', 12, 'N1', 6, 'N2', 1, 'O1', 4, 'O2', 1);

    % --- 16 Antenna Ports ---
    % Configurations supported for 16 ports
    cfg(end+1) = struct('NPorts', 16, 'N1', 4, 'N2', 2, 'O1', 4, 'O2', 4); % Note: (4,2) in table
    cfg(end+1) = struct('NPorts', 16, 'N1', 8, 'N2', 1, 'O1', 4, 'O2', 1); % Note: (8,1) in table

    % --- 24 Antenna Ports ---
    % Configurations supported for 24 ports
    cfg(end+1) = struct('NPorts', 24, 'N1', 4, 'N2', 3, 'O1', 4, 'O2', 4); % Note: (4,3) in table
    cfg(end+1) = struct('NPorts', 24, 'N1', 6, 'N2', 2, 'O1', 4, 'O2', 4); % Note: (6,2) in table
    cfg(end+1) = struct('NPorts', 24, 'N1', 12, 'N2', 1, 'O1', 4, 'O2', 1); % Note: (12,1) in table

    % --- 32 Antenna Ports ---
    % Configurations supported for 32 ports
    cfg(end+1) = struct('NPorts', 32, 'N1', 4, 'N2', 4, 'O1', 4, 'O2', 4); % Note: (4,4) in table
    cfg(end+1) = struct('NPorts', 32, 'N1', 8, 'N2', 2, 'O1', 4, 'O2', 4); % Note: (8,2) in table
    cfg(end+1) = struct('NPorts', 32, 'N1', 16, 'N2', 1, 'O1', 4, 'O2', 1); % Note: (16,1) in table
end

function [i11, i12, i13, i2] = computeInputs(i1, i2, N2, nLayers) 
    % computeInputs: Extracts codebook indices based on layer count and antenna geometry.
    
    % Get i1,1 (First codebook index)
    % This is always the first element of the composite index i1.
    i11 = i1{1};
    
    % Pass through i2 directly
    i2 = i2;

    % Logic for i1,2 (Second codebook index)
    % According to 3GPP TS 38.214 5.2.2.2.1:
    % If N2 = 1, the UE shall only use i1,2 = 0 and shall not report i1,2.
    if N2 == 1
        i12 = 0;
    else
        % If N2 > 1, i1,2 is reported as the second element.
        i12 = i1{2};
    end

    % Logic for i1,3 (Third codebook index for higher ranks)
    % i1,3 is only used when the number of layers v is in {2, 3, 4}.
    % Ideally, the composite index is i1 = [i1,1 i1,2 i1,3] for these layers.
    if nLayers == 2 || nLayers == 3 || nLayers == 4
        i13 = i1{3};
    else
        % For rank 1 or rank > 4, i1,3 is not part of the PMI.
        i13 = 0;
    end
end

function [l, m, lp, mp, lpp, mpp, lppp, mppp, p, n] = getBeamIndices(codebookMode, nPorts, nLayers, i11, i12, i13, i2, N1, N2, O1, O2)
    % GETBEAMINDICES Derives the spatial beam indices (l, m) and phase indices (n, p)
    % based on the provided CSI parameters and Codebook Mode.

    % Initialize all outputs to 0
    [l, m, lp, mp, lpp, mpp, lppp, mppp, p] = deal(0);
    
    % =========================================================================
    % RANK 1 (1 Layer)
    % =========================================================================
    if nLayers == 1
        if codebookMode == 1
            % Mode 1: Direct mapping.
            % l = i1,1; m = i1,2; n = i2 (0..3)
            l = i11; m = i12; n = i2;
        else % codebookMode == 2
            % Mode 2: Beam selection depends on i2
            if N2 == 1
                % Linear Array (N2=1)
                % i2 maps to 4 consecutive beams (over-sampled by 2)
                % n cycles 0..3 for each beam group
                n = mod(i2, 4);
                offset_l = floor(i2 / 4);
                l = 2 * i11 + offset_l; % Base l is multiplied by 2
                m = 0;
            else 
                % Planar Array (N2 > 1)
                % i2 determines offsets for both dimensions l and m.
                % Groups of 4: (0,0), (1,0), (0,1), (1,1) logic
                offset_l = [0, 1, 0, 1]; 
                offset_m = [0, 0, 1, 1];
                group_idx = floor(i2 / 4) + 1;
                
                l = 2 * i11 + offset_l(group_idx);
                m = 2 * i12 + offset_m(group_idx);
                n = mod(i2, 4);
            end
        end

    % =========================================================================
    % RANK 2 (2 Layers)
    % =========================================================================
    elseif nLayers == 2
        % Calculate beam offsets k1, k2 from i1,3
        [k1, k2] = getK1K2(nLayers, i13, N1, N2, O1, O2);

        if codebookMode == 1
            % Mode 1: Layer 1 (l,m), Layer 2 (l+k1, m+k2)
            l = i11; m = i12; n = i2;
            lp = l + k1; mp = m + k2;

        elseif codebookMode == 2 
            % Mode 2: Uses 2*i1 basis with offsets derived from i2
            if N2 == 1  
                % Linear Array
                n = mod(i2,2);
                offset_l = floor(i2 / 2);
                l = 2 * i11 + offset_l;
                lp = l + k1; % Second beam applies k1 offset
                m = 0;
                mp = 0;
            else % N2 > 1 
                % Planar Array: i2 maps to offsets (0,0), (1,0), (0,1), (1,1)
                % Only i2 = 0..7 are used (groups of 2)
                n = mod(i2,2);
                offset_l = [0, 1, 0, 1];
                offset_m = [0, 0, 1, 1];
                group_idx = floor(i2 / 2) + 1;
                
                l  = 2 * i11 + offset_l(group_idx);
                m  = 2 * i12 + offset_m(group_idx);
                lp = l + k1;
                mp = m + k2;
            end
        end

    % =========================================================================
    % RANK 3 & 4 (3-4 Layers)
    % =========================================================================
    elseif (nLayers == 3) || (nLayers == 4)
        if nPorts < 16
            % For small port counts, use k1, k2 mapping
            [k1, k2] = getK1K2(nLayers, i13, N1, N2, O1, O2);
            l = i11; m = i12; n = i2;
            lp = l + k1; mp = m + k2;
        else 
            % For >= 16 ports, i1,3 maps to 'p' (theta_p parameter)
            l = i11; m = i12; p = i13; n = i2;
        end

    % =========================================================================
    % RANK 5 & 6 (5-6 Layers)
    % =========================================================================
    elseif nLayers == 5 || nLayers == 6
        % These ranks typically use 3 orthogonal beams derived from O1/O2
        if N2 > 1 
            % Planar: (l,m), (l+O1, m), (l, m+O2)
            l = i11; lp = i11 + O1; lpp = i11 + O1; 
            m = i12; mp = i12; mpp = i12 + O2;
            n = i2;
        elseif N2 == 1 && N1 > 2
            % Linear: (l,0), (l+O1,0), (l+2*O1,0)
            l = i11; lp = i11 + O1; lpp = i11 + 2*O1; 
            m = 0; mp = 0; mpp = 0;
            n = i2;
        else
            error('Invalid Parameters for Rank 5/6');
        end
    
    % =========================================================================
    % RANK 7 & 8 (7-8 Layers)
    % =========================================================================
    elseif nLayers == 7 || nLayers == 8
        % Use 4 orthogonal beams
        if N2 == 1 
            % Linear: l, l+O1, l+2O1, l+3O1
            l = i11; lp = i11 + O1; lpp = i11 + 2*O1; lppp = i11 + 3*O1;
            m = 0;   mp = 0;        mpp = 0;          mppp = 0;
        else % N2 > 1
            % Planar: (l,m), (l+O1,m), (l,m+O2), (l+O1,m+O2)
            l = i11; lp = i11 + O1; lpp = i11;        lppp = i11 + O1;
            m = i12; mp = i12;      mpp = i12 + O2;   mppp = i12 + O2;
        end
        n = i2;
    end   
end

function [k1, k2] = getK1K2(layers, i13, N1, N2, O1, O2)
% GETK1K2 Maps the codebook index i1,3 to beam offsets k1 and k2.
%
%   This mapping depends on the number of layers (Rank) and the 
%   antenna port configuration (N1, N2).
%
%   References: 3GPP TS 38.214 V17.1.0 Section 5.2.2.2.1

    k1 = NaN; 
    k2 = NaN;

    % =====================================================================
    % 2-Layer Reporting (Rank 2)
    % Reference: Table 5.2.2.2.1-3
    % =====================================================================
    if layers == 2
        
        % Case 1: Planar Array where N1 > N2 > 1
        % Mapping covers 4 possible values of i1,3
        if (N1 > N2) && (N2 > 1)
            switch i13
                case 0, k1 = 0;    k2 = 0;
                case 1, k1 = O1;   k2 = 0;
                case 2, k1 = 0;    k2 = O2;
                case 3, k1 = 2*O1; k2 = 0;
            end

        % Case 2: Square Planar Array (N1 = N2 > 1)
        elseif (N1 == N2) && (N1 > 1)
            switch i13
                case 0, k1 = 0;    k2 = 0;
                case 1, k1 = O1;   k2 = 0;
                case 2, k1 = 0;    k2 = O2;
                case 3, k1 = O1;   k2 = O2; % Diagonal offset
            end

        % Case 3: Linear Array (N1 = 2, N2 = 1)
        % Only 2 values (0, 1) supported
        elseif (N1 == 2) && (N2 == 1)
            switch i13
                case 0, k1 = 0;    k2 = 0;
                case 1, k1 = O1;   k2 = 0;
            end

        % Case 4: Linear Array (N1 > 2, N2 = 1)
        % Mapping covers 4 values
        elseif (N1 > 2) && (N2 == 1)
            switch i13
                case 0, k1 = 0;    k2 = 0;
                case 1, k1 = O1;   k2 = 0;
                case 2, k1 = 2*O1; k2 = 0;
                case 3, k1 = 3*O1; k2 = 0;
            end
        end

    % =====================================================================
    % 3-Layer and 4-Layer Reporting
    % Reference: Table 5.2.2.2.1-4
    % =====================================================================
    elseif layers == 3 || layers == 4
        
        % Case 1: Linear Array (N1 = 2, N2 = 1)
        % Only i1,3 = 0 is valid
        if (N1 == 2) && (N2 == 1)
            if i13 == 0, k1 = O1; k2 = 0; end
            
        % Case 2: Linear Array (N1 = 4, N2 = 1)
        % Supports i1,3 = 0, 1, 2
        elseif (N1 == 4) && (N2 == 1)
            switch i13
                case 0, k1 = O1;   k2 = 0;
                case 1, k1 = 2*O1; k2 = 0;
                case 2, k1 = 3*O1; k2 = 0;
            end
            
        % Case 3: Linear Array (N1 = 6, N2 = 1)
        % Supports i1,3 = 0, 1, 2, 3
        elseif (N1 == 6) && (N2 == 1)
            switch i13
                case 0, k1 = O1;   k2 = 0;
                case 1, k1 = 2*O1; k2 = 0;
                case 2, k1 = 3*O1; k2 = 0;
                case 3, k1 = 4*O1; k2 = 0;
            end
            
        % Case 4: Planar Array (N1 = 2, N2 = 2)
        % Supports i1,3 = 0, 1, 2
        elseif (N1 == 2) && (N2 == 2)
            switch i13
                case 0, k1 = O1;   k2 = 0;
                case 1, k1 = 0;    k2 = O2;
                case 2, k1 = O1;   k2 = O2;
            end
            
        % Case 5: Planar Array (N1 = 3, N2 = 2)
        % Supports i1,3 = 0, 1, 2, 3
        elseif (N1 == 3) && (N2 == 2)
            switch i13
                case 0, k1 = O1;   k2 = 0;
                case 1, k1 = 0;    k2 = O2;
                case 2, k1 = O1;   k2 = O2;
                case 3, k1 = 2*O1; k2 = 0;
            end
        end
    end
end

function v = computeBeam(l, m, N1, N2, O1, O2, phaseFactor)
% COMPUTEBEAM Generates the DFT beam vector v_{l,m} for a given spatial direction.
%
%   Inputs:
%       l, m        - Beam indices for the 1st and 2nd dimensions.
%       N1, N2      - Number of antenna ports in 1st and 2nd dimensions.
%       O1, O2      - Oversampling factors.
%       phaseFactor - Scalar for the exponent (Typically 2 for 2*pi).
%
%   Output:
%       v           - The resulting precoding beam vector v_{l,m}.
%

    % --- Compute u_m (2nd Dimension DFT vector) ---
    if N2 == 1
        % For a 1D linear array (N2=1), the second dimension component is scalar 1.
        u_n2 = 1;
    else 
        % For a 2D planar array (N2 > 1).
        n2 = (0:N2-1).';
        u_n2 = exp(1j * phaseFactor * pi * m * n2 / (O2 * N2));
    end
    
    % --- Compute u_l (1st Dimension DFT vector) ---
    % Kronecker product of the 1st dim vector and 2nd dim vector.
    n1 = (0:N1-1).';
    u_n1 = exp(1j * phaseFactor * pi * l * n1 / (O1 * N1));
    
    % --- Compute v_{l,m} ---
    v = kron(u_n1, u_n2);
end