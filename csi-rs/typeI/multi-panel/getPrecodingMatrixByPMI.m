% ---------------------------------------------------------
% This function use to get Precoding Matrix for each PMI
% UE will report the PMI number and the number of Ports and Layers
% ---------------------------------------------------------
function W = getPrecodingMatrixByPMI(cfg, nLayers, pmi)
    [i1, i2] = getParameters(cfg, nLayers, pmi);

    W = generateTypeISinglePanelPrecoder(cfg, nLayers, i1, i2);
    disp(W);
end

% ---------------------------------------------------------
% This function use to create a parameters for the next function
% ---------------------------------------------------------
function [i1, i2] = getParameters(cfg, nLayers, pmi)
    N1 = cfg.CodebookConfig.N1;
    N2 = cfg.CodebookConfig.N2;
    O1 = cfg.CodebookConfig.O1;
    O2 = cfg.CodebookConfig.O2;
    codebookMode = cfg.CodebookConfig.codebookMode;

    [i11_lookup, i12_lookup, i13_lookup, ...
    i14_lookup, i20_lookup, i2x_lookup] = ...
    lookupPMITable(N1, N2, O1, O2, nLayers, Ng, codebookMode);
   
    % Matlab index start from 1
    pmi_idx = pmi + 1;

    % Because of i14_lookup and i2x_lookup contains value for i14q, q = 0, .. Ng - 1 
    num_col_i14 = size(i14_lookup, 2); 
    num_col_i2x = size(i2x_lookup, 2);

    i14 = zeros(1, num_col_i14); 
    i2x = zeros(1, num_col_i2x);

    % Compute value for i14
    % i14 = [i14q]
    for q = 1:num_col_i14
        i14(q) = i14_lookup(pmi_idx, q);
    end

    % Compute value for i12
    % i14 = [i12x]
    for x = 1:num_col_i2x
        i2x(x) = i2x_lookup(pmi_idx, x);
    end

    % Get i11, i12, i13, i20
    i11 = i11_lookup(pmi_idx);
    i12 = i12_lookup(pmi_idx);
    i13 = i13_lookup(pmi_idx);
    i20 = i20_lookup(pmi_idx);

    % Create a input parameters for the next function
    i1 = {i11, i12, i13, i14};
    i2 = [i20, i2x];
end