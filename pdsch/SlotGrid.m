function grid = SlotGrid(carrier, nPorts)

    % Calculate total number of subcarriers (K)
    % 1 Resource Block (RB) is fixed to 12 Subcarriers in 5G NR
    nSizeGrid = double(carrier.NSizeGrid) * 12; 

    % Retrieve number of OFDM symbols per slot (L)
    symbolsPerSlot = carrier.SymbolsPerSlot;

    % -----------------------------------------------------------
    % Initialize the grid with complex zeros.
    % Data type is explicitly set to complex double for high-precision IFFT.
    % -----------------------------------------------------------
    grid = complex(zeros([nSizeGrid, symbolsPerSlot, nPorts], 'double'));
end