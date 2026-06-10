function outSymbols = modulation(inBits, modType)
    switch upper(modType)
        case 'PI/2-BPSK'
            outSymbols = modPI2BPSK(inBits);

        case 'BPSK'
            outSymbols = modBPSK(inBits);

        case 'QPSK'
            outSymbols = modQPSK(inBits);

        case '16QAM'
            outSymbols = mod16QAM(inBits);

        case '64QAM'
            outSymbols = mod64QAM(inBits);

        case '256QAM'
            outSymbols = mod256QAM(inBits);

        otherwise
            error('Unsupported modulation');
    end
end

function outSymbols = modPI2BPSK(bits)
    outSymbols = zeros(length(bits), 1);
    for idx = 1:length(bits);
        complex_part = (1 - 2*bits(idx)) + 1j*(1 - 2*bits(idx));
        
        phase_shift = exp(1j * (pi/2) * mod(idx - 1, 2));
        
        outSymbols(idx) = (phase_shift / sqrt(2)) * complex_part;
    end
end

function outSymbols = modBPSK(bits)
    outSymbols = zeros(length(bits), 1);
    for idx = 1:length(bits);
        complex_part = (1 - 2*bits(idx)) + 1j*(1 - 2*bits(idx));
        
        phase_shift = 1;
        
        outSymbols(idx) = (phase_shift / sqrt(2)) * complex_part;
    end
end

function outSymbols = modQPSK(bits)
    bits = bits(:);                 
    b = reshape(bits, 2, []).';    

    I = 1 - 2*b(:,1);               
    Q = 1 - 2*b(:,2);              

    outSymbols = (I + 1j*Q) / sqrt(2);      
end

function outSymbols = mod16QAM(bits)
    bits = bits(:); 
    
    if mod(length(bits), 4) ~= 0
        error('Số lượng bit đầu vào phải là bội số của 4 cho 16QAM.');
    end

    b = reshape(bits, 4, []).'; 

    I = (1 - 2*b(:,1)) .* (2 - (1 - 2*b(:,3)));
    
    Q = (1 - 2*b(:,2)) .* (2 - (1 - 2*b(:,4)));

    outSymbols = (I + 1j*Q) / sqrt(10); 
end

function outSymbols = mod64QAM(bits)
    bits = bits(:);
    b = reshape(bits, 6, []).'; 

    I = (1 - 2*b(:,1)) .* (4 - (1 - 2*b(:,3)) .* (2 - (1 - 2*b(:,5))));
    Q = (1 - 2*b(:,2)) .* (4 - (1 - 2*b(:,4)) .* (2 - (1 - 2*b(:,6))));

    outSymbols = (I + 1j*Q) / sqrt(42);
end

function outSymbols = mod256QAM(bits)
    bits = bits(:);
    b = reshape(bits, 8, []).'; 

    I = (1 - 2*b(:,1)) .* (8 - (1 - 2*b(:,3)) .* (4 - (1 - 2*b(:,5)) .* (2 - (1 - 2*b(:,7)))));
    Q = (1 - 2*b(:,2)) .* (8 - (1 - 2*b(:,4)) .* (4 - (1 - 2*b(:,6)) .* (2 - (1 - 2*b(:,8)))));

    outSymbols = (I + 1j*Q) / sqrt(170);
end