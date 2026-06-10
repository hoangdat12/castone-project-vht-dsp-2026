function outBits = scrambling(inBits, c_init)
    N = length(inBits);

    c = GoldSequence(c_init, N);

    outBits = xor(logical(inBits(:)), c(:));
end

function c = GoldSequence(c_init, N)
    x1 = zeros(1, 31); 
    x2 = zeros(1, 31);
    x1(1) = 1;

    % Load c_init into x2 (LSB first)
    for i = 1:31
        x2(i) = bitget(c_init, i);
    end

    %-----------------------------------------
    % 2. Generate L = N + 1600 bits
    %    (first 1600 bits are discarded as per 3GPP)
    %-----------------------------------------
    L = N + 1600;
    seq = zeros(L,1);

    %-----------------------------------------
    % 3. Generate sequences
    %    Output: seq(n) = x1(1) XOR x2(1)
    %
    %    Update rules:
    %       new_x1 = ( x1(1) + x1(4) ) mod 2
    %       new_x2 = ( x2(1) + x2(2) + x2(3) + x2(4) ) mod 2
    %-----------------------------------------
    for n = 1:L
        % Gold sequence output
        seq(n) = xor(x1(1), x2(1));

        % Feedback computation
        new_x1 = xor(x1(1), x1(4));
        new_x2 = xor(xor(x2(4), x2(3)), xor(x2(2), x2(1)));

        % Shift right and append new bits
        x1 = [x1(2:end), new_x1];
        x2 = [x2(2:end), new_x2];
    end

    %-----------------------------------------
    % 4. Discard the first 1600 bits → output N bits
    %-----------------------------------------
    c = logical(seq(1601:end));
end

