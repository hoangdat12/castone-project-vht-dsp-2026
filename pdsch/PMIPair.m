% -----------------------------------------------------------------
% This function calculates the correlation between two PMIs
% It performs an element-wise inner product (Frobenius inner product)
% It return:
%   - C_mn: The complex scalar correlation result
% -----------------------------------------------------------------
function C_mn = PMIPair(PMI_m, PMI_n)

    % -----------------------------------------------------------------
    % INPUT VALIDATION
    % -----------------------------------------------------------------
    % Check if dimensions of both matrices match
    if any(size(PMI_m) ~= size(PMI_n))
        error('PMIPair:DimensionMismatch', 'Input matrices must have the same size.');
    end

    % -----------------------------------------------------------------
    % CORRELATION CALCULATION
    % -----------------------------------------------------------------
    [numRows, numCols] = size(PMI_m);
    C_mn = 0;
    
    % Loop through each element to calculate the sum of products
    for i = 1:numRows
        for j = 1:numCols
            % Accumulate: element * conjugate(element)
            C_mn = C_mn + PMI_m(i,j) * conj(PMI_n(i,j));
        end
    end
end