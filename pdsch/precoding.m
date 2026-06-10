function precodedGrid = precoding(txGrid, W)
% txGrid: [K x L x P], W = [P x v]
    % Extract K and L from txGrid, because of the data carries in the nLayers
    % so we don't care about P at this step
    [K, L, ~] = size(txGrid);
    
    % Extract nPorts and nLayers from the W matrix
    [nPorts, nLayers] = size(W);
    
    % Extract the data in the nLayers
    layersIn = txGrid(:, :, 1:nLayers);
    
    % Reshape the matrix the output with the format [K*L x nLayers]
    layersFlat = reshape(layersIn, K*L, nLayers);
    
    % Perform Precoding: [K*L, nLayers] * [nLayers, nPorts] = [K*L, nPorts]
    precodedFlat = layersFlat * (W.');
    
    % Reconstruct the output [K, L, nPorts]
    precodedGrid = reshape(precodedFlat, K, L, nPorts);
end