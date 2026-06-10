function grid = ResourceGrid(carrier, nPorts)

    % Calculate total number of subcarriers (K)
    % 1 Resource Block (RB) is fixed to 12 Subcarriers in 5G NR
    nSizeGrid = double(carrier.NSizeGrid) * 12; 

    % Retrieve number of OFDM symbols per slot
    symbolsPerSlot = carrier.SymbolsPerSlot;
    
    % Retrieve total number of slots per 10ms frame based on numerology (mu)
    slotsPerFrame = carrier.SlotsPerFrame; 
    
    % Calculate total number of OFDM symbols in one 10ms frame (L_frame)
    symbolsPerFrame = symbolsPerSlot * slotsPerFrame;

    % -----------------------------------------------------------
    % Initialize the frame grid with complex zeros.
    % Data type is explicitly set to complex double for high-precision IFFT.
    % -----------------------------------------------------------
    grid = complex(zeros([nSizeGrid, symbolsPerFrame, nPorts], 'double'));
end