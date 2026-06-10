% ---------------------------------------------------------
% The output format for this function 
% i11_lookup = [PMI_length x 1]
% i12_lookup = [PMI_length x 1]
% i13_lookup = [PMI_length x 1]
% i2_lookup = [PMI_length x 1]
% ---------------------------------------------------------
function [i11_lookup, ...
    i12_lookup, ...
    i13_lookup, ...
    i2_lookup ...
] = lookupPMITable(N1, N2, O1, O2, nLayers, codebookMode)
    % Find the end value of each range of each value [i11, i12, i13, 14]
    % Because of they all start at the 0 value and end with X value
    % X will be returned at this function
    [idx11_end, idx12_end, idx13_end, idx2_end] = findRangeValues(N1, N2, O1, O2, nLayers, codebookMode);

    % After determined range values of i11, i12, i13, i2
    % Create Lookup table.
    [i11_lookup, i12_lookup, i13_lookup, i2_lookup] = genLookupTable(idx11_end, idx12_end, idx13_end, idx2_end);
end

function [i11_lookup, i12_lookup, i13_lookup, i2_lookup] = genLookupTable(idx11_end, idx12_end, idx13_end, idx2_end)
    % The number of PMI index
    N = (idx11_end+1) * (idx12_end+1) * ...
        (idx13_end+1) * (idx2_end+1);

    % Preallocate
    i11_lookup = zeros(N,1);
    i12_lookup = zeros(N,1);
    i13_lookup = zeros(N,1);
    i2_lookup  = zeros(N,1);

    n = 1;
    for idx11 = 0:idx11_end
        for idx12 = 0:idx12_end
            for idx13 = 0:idx13_end
                for idx2 = 0:idx2_end
                    i11_lookup(n) = idx11;
                    i12_lookup(n) = idx12;
                    i13_lookup(n) = idx13;
                    i2_lookup(n)  = idx2;
                    n = n + 1;
                end
            end
        end
    end
end
