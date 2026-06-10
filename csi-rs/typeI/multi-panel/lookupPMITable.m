% -----------------------------------------------------
% The output format for this function 
% i11_lookup = [PMI_length x 1]
% i12_lookup = [PMI_length x 1]
% i13_lookup = [PMI_length x 1]
% i14_lookup = [PMI_length x (Ng - 1)]
% i20_lookup = [PMI_length x 1]
% i2x_lookup = [PMI_length x (Ng - 1)]
% -----------------------------------------------------
function [...
    i11_lookup, ...
    i12_lookup, ...
    i13_lookup, ...
    i14_lookup, ...
    i20_lookup, ...
    i2x_lookup ...
] = lookupPMITable( ...
    N1, N2, O1, O2, ...
    nLayers, Ng, codebookMode ...
)
    % Initial value for idx
    idx11_end = 0;
    idx12_end = 0;
    idx13_end = 0;
    idx14_end = 0;
    idx20_end = 0;
    idx2x_end = 0;

    % Start finding the range value of each parameters in pmi
    % From these values, we will use to create a pmi table
    switch nLayers
        case 1
            idx13_end = findRangeValueOfI13(N1, N2);

            if codebookMode == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx14_end = 3;
                idx20_end = 3;
                idx2x_end = 0;

            elseif codebookMode == 2
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx14_end = 3;
                idx20_end = 3;
                idx2x_end = 1;
            else
                warning("Invalid codebook mode!");
            end
        
        case 2
            idx13_end = findRangeValueOfI13(N1, N2);

            if codebookMode == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx14_end = 3;
                idx20_end = 1;
                idx2x_end = 0;

            elseif codebookMode == 2
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx14_end = 3;
                idx20_end = 3;
                idx2x_end = 1;

            else
                warning("Invalid codebook mode!");
            end

        case {3, 4}
            idx13_end = findRangeValueOfI13(N1, N2);

            if codebookMode == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx14_end = 3;
                idx20_end = 1;
                idx2x_end = 0;

            elseif codebookMode == 2
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx14_end = 3;
                idx20_end = 1;
                idx2x_end = 1;

            else
                warning("Invalid codebook mode!");
            end
        
        otherwise
    end

    % Compute lookup table
    [i11_lookup, i12_lookup, i13_lookup, i14_lookup, i20_lookup, i2x_lookup] = genLookupTable(codebookMode, ...
                                                                    Ng,...
                                                                    idx11_end, ...
                                                                    idx12_end, ...
                                                                    idx13_end, ...
                                                                    idx14_end, ...
                                                                    idx20_end, ...
                                                                    idx2x_end);
end

% -----------------------------------------------------
% The output format for this function 
% i11_lookup = [PMI_length x 1]
% i12_lookup = [PMI_length x 1]
% i13_lookup = [PMI_length x 1]
% i14_lookup = [PMI_length x (Ng - 1)]
% i20_lookup = [PMI_length x 1]
% i2x_lookup = [PMI_length x (Ng - 1)]
% -----------------------------------------------------
function [ ...
    i11_lookup, ...
    i12_lookup, ...
    i13_lookup, ...
    i14_lookup, ...
    i20_lookup, ...
    i2x_lookup  ...
] = genLookupTable( ...
    codebookMode, ...
    Ng, ...
    idx11_end, ...
    idx12_end, ...
    idx13_end, ...
    idx14_end, ...
    idx20_end, ...
    idx2x_end  ...
)

    % In the case codebookMode = 1 => i14 = 0, ... Ng - 1
    % In the case codebookMode = 2 => i14 = 0, ... Ng
    if codebookMode == 1
        num_i14 = Ng - 1; 
    else
        num_i14 = Ng;     
    end

    % The i2x parameters just only exist in the codebook mode 2
    % It contains 2 elements: i21, i22. i20 = i2 for all case
    num_i2x = 2; 

    % Total element of i14. Because i14 is a multi-demension. Each row equivalent with i14q.
    n_i14_combs = (idx14_end + 1)^num_i14;

    if codebookMode == 2
        base_i2x = idx2x_end + 1; 
        n_i2x_combs = base_i2x^num_i2x; 
    else
        n_i2x_combs = 1;
    end

    % Total value of PMI 
    N = (idx11_end + 1) * ...
        (idx12_end + 1) * ...
        (idx13_end + 1) * ...
        (idx20_end + 1) * ...
         n_i14_combs    * ...
         n_i2x_combs;

    % Preallocate
    i11_lookup = zeros(N, 1);
    i12_lookup = zeros(N, 1);
    i13_lookup = zeros(N, 1);
    i20_lookup = zeros(N, 1);
    i14_lookup = zeros(N, num_i14); 
    i2x_lookup = zeros(N, num_i2x); 

    % Generate Lookup
    n = 1;

    % Loop to create PMI table
    for idx11 = 0:idx11_end
    for idx12 = 0:idx12_end
    for idx13 = 0:idx13_end
    for idx14 = 0:n_i14_combs-1
    for idx20 = 0:idx20_end
    for idx2x = 0:n_i2x_combs-1

        i11_lookup(n) = idx11;
        i12_lookup(n) = idx12;
        i13_lookup(n) = idx13;
        i20_lookup(n) = idx20;

        % i14 (Start = 0)
        i14_lookup(n,:) = decodeIndex(idx14, num_i14, idx14_end, 0);

        if codebookMode == 2
            i2x_lookup(n,:) = decodeIndex( ...
                idx2x, ...
                num_i2x, ...
                idx2x_end, ...
                0 ... 
            );
        else
            i2x_lookup(n,:) = zeros(1, num_i2x); 
        end

        n = n + 1;

    end
    end
    end
    end
    end
    end
end

% ---------------------------------------------------------
% PURPOSE:
%   Convert a single integer index "idx" into a vector of nElem elements
%   using a base-N representation, where:
%       base = maxVal - startVal + 1
%
% APPLICATIONS:
%   - PMI decoding
%   - Decomposing beam / phase / amplitude indices
% ---------------------------------------------------------
function vec = decodeIndex(idx, nElem, maxVal, startVal)
    base = maxVal - startVal + 1;
    vec  = zeros(1, nElem);

    tmp = idx;
    for k = nElem:-1:1
        vec(k) = mod(tmp, base) + startVal;
        tmp    = floor(tmp / base);
    end
end

% ---------------------------------------------------------
% Mapping of i1,3 to k1 and k2 for 3-layer and 4-layer CSI reporting
% Reference: Table 5.2.2.2.2-2
% Returns the maximum index of i1,3 (idx13_end) based on N1, N2
% ---------------------------------------------------------
function idx13_end = findRangeValueOfI13(N1, N2)
    % Case: N1 = 2, N2 = 1 -> Only i1,3 = 0 exists
    if (N1 == 2 && N2 == 1)
        idx13_end = 0;
        
    % Case: N1 = 4, N2 = 1 OR N1 = 2, N2 = 2 -> i1,3 = {0, 1, 2}
    elseif (N1 == 4 && N2 == 1) || (N1 == 2 && N2 == 2)
        idx13_end = 2;
        
    % Case: N1 = 8, N2 = 1 OR N1 = 4, N2 = 2 -> i1,3 = {0, 1, 2, 3}
    elseif (N1 == 8 && N2 == 1) || (N1 == 4 && N2 == 2)
        idx13_end = 3;
        
    % Default case (if configuration is not in the table)
    else
        idx13_end = -1; % Indicates error or invalid configuration
    end
end
