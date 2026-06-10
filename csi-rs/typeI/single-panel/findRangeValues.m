% This function will find the end value of each range of each value [i11, i12, i13, 14]
% Because of they all start at the 0 value and end with X value
% X will be returned at this function
% It only use for Type I codebook - Single Layer
function [idx11_end, idx12_end, idx13_end, idx2_end] = findRangeValues(N1, N2, O1, O2, nLayers, codebookMode)
% Initial value for the end value of i11, i12, i13, i14
    idx11_end = 0;
    idx12_end = 0;
    idx13_end = 0;
    idx2_end  = 0;

    % ---------------------------------------------------------
    % In the type I single layer
    % + v ∉ {2, 3, 4} will not be include i13
    % + v ∈ {2, 3, 4} will be include i13
    % In the code below will identify the ending index for i11, i12, i13, i14
    % After identify the ending values, will loop and get the PMI Lookup Table
    % ---------------------------------------------------------
    switch nLayers
        case 1
            idx13_end = 0;

            if codebookMode == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx2_end  = 3;
            elseif codebookMode == 2
                if N2 > 1
                    idx11_end = (N1 * O1) / 2 - 1;
                    idx12_end = (N2 * O2) / 2 - 1;
                    idx2_end  = 15;
                else 
                    idx11_end = (N1 * O1) / 2 - 1;
                    idx12_end = 0;
                    idx2_end  = 15;
                end
            else
                warning("Invalid!");
            end

        case 2
            if codebookMode == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx2_end  = 1;
            elseif codebookMode == 2
                if N2 > 1
                    idx11_end = (N1 * O1) / 2 - 1;
                    idx12_end = (N2 * O2) / 2 - 1;
                    idx2_end  = 7;
                else 
                    idx11_end = (N1 * O1) / 2 - 1;
                    idx12_end = 0;
                    idx2_end  = 7;
                end
            else
                warning("Invalid!");
            end

            idx13_end = findRangeValueOfI13Layer2(N1, N2);

        case 3
            nPorts = 2*N1*N2;
            if nPorts < 16
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx13_end = findRangeValueOfI13Layer34(N1, N2);
                idx2_end  = 1;
            else
                idx11_end = (N1 * O1) / 2 - 1;
                idx12_end = (N2 * O2) - 1;
                idx13_end = 3;
                idx2_end  = 1;
            end

        case 4
            nPorts = 2*N1*N2;
            if nPorts < 16
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx13_end = findRangeValueOfI13Layer34(N1, N2);
                idx2_end  = 1;
            else
                idx11_end = (N1 * O1) / 2 - 1;
                idx12_end = (N2 * O2) - 1;
                idx13_end = 3;
                idx2_end  = 1;
            end

        case 5
            idx13_end = 0;
            if N2 > 1 
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx2_end  = 1; 
            elseif N1 > 2 && N2 == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = 0;
                idx2_end  = 1;
            else
                warning("Invalid parameters!");
            end

        case 6
            idx13_end = 0;

            if N2 > 1 
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
                idx2_end  = 1; 
            elseif N1 > 2 && N2 == 1
                idx11_end = (N1 * O1) - 1;
                idx12_end = 0;
                idx2_end  = 1;
            else
                warning("Invalid parameters!");
            end

        case 7
            idx13_end = 0; 
            idx2_end  = 1; 
            
            if (N1 == 4 && N2 == 1)
                idx11_end = (N1 * O1 / 2) - 1;
                idx12_end = 0;
            elseif (N1 > 4 && N2 == 1)
                idx11_end = (N1 * O1) - 1;
                idx12_end = 0;
            elseif (N1 == 2 && N2 == 2)
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
            elseif (N1 > 2 && N2 == 2)
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2 / 2) - 1;
            elseif (N1 > 2 && N2 > 2)
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
            else
                warning("Invalid parameters for Layer 7!");
            end

        case 8
            idx13_end = 0; 
            idx2_end  = 1; 
            
            if (N1 == 4 && N2 == 1)
                idx11_end = (N1 * O1 / 2) - 1;
                idx12_end = 0;
            elseif (N1 > 4 && N2 == 1)
                idx11_end = (N1 * O1) - 1;
                idx12_end = 0;
            elseif (N1 == 2 && N2 == 2)
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
            elseif (N1 > 2 && N2 == 2)
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2 / 2) - 1;
            elseif (N1 > 2 && N2 > 2)
                idx11_end = (N1 * O1) - 1;
                idx12_end = (N2 * O2) - 1;
            else
                warning("Invalid parameters for Layer 8!");
            end

        otherwise
    end
end

%% ----------- HELPER FUNCTION -------------


% ---------------------------------------------------------
% In 2 Layers, some table will not include the i1,3
% The range value of i1,3 is determined based on the N1, N2
% This function is used when the formula not include i1,3 range values
% Reference: Table 5.2.2.2.1-3 - Ts 138.214 3GPP
% ---------------------------------------------------------
function idx13_end = findRangeValueOfI13Layer2(N1, N2)
    if (N1 == 2 && N2 == 1)
        idx13_end = 1; 
    else
        idx13_end = 3;
    end
end

% ---------------------------------------------------------
% In 3, 4 Layers, some table will not include the i1,3
% The range value of i1,3 is determined based on the N1, N2
% This function is used when the formula not include i1,3 range values
% Reference: Table 5.2.2.2.1-4 - Ts 138.214 3GPP
% ---------------------------------------------------------
function idx13_end = findRangeValueOfI13Layer34(N1, N2)
    nPorts = 2*N1*N2;
    if nPorts < 16
        if (N1 == 2 && N2 == 1)
            idx13_end = 0;
        elseif (N1 == 4 && N2 == 1) || (N1 == 2 && N2 == 2)
            idx13_end = 2;
        elseif (N1 == 6 && N2 == 1) || (N1 == 3 && N2 == 2)
            idx13_end = 3;
        else
            idx13_end = 0; 
        end
    else
        idx13_end = 3;
    end
end