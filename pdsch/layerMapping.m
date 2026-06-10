function outBits = layerMapping(modSymbols, nLayers)
    totalSymbols = length(modSymbols);

    if nLayers > 4
        error("This function only support less than 4 layers!");
    end
    
    if mod(totalSymbols, nLayers) ~= 0
        error('Number of symbols is not devided for nLayers!');
    end

    % Calculate number of symbols per layer.
    numbBitsPerLayers = totalSymbols / nLayers;
    % Pre-allocate output matrix (Layers are columns).
    outBits = zeros(numbBitsPerLayers, nLayers);

    for v = 0 : (nLayers - 1) 
        % Adjust for MATLAB 1-based indexing (Layer 0 -> Column 1)
        colIndex = v + 1; 
        
        % Distribute symbols in a round-robin fashion (Table 7.3.1.3-1).
        % Mathematical logic: x(i) = d(v + i * nLayers)
        % MATLAB Syntax: start : step : end
        outBits(:, colIndex) = modSymbols(colIndex : nLayers : end);
    end
end