function cbs = cbSegmentation(in, bgn)

    % Transport block size
    B = length(in);

    % --- Basic setup based on TS 38.212 Section 5.2.2 ---
    % Kcb: Maximum allowed size (in bits) of a code block before LDPC encoding.
    % Kb: Number of base graph columns used to determine the LDPC input block size.
    if bgn == 1
        Kcb = 8448; 
        Kb = 22;
    else % bgn == 2
        Kcb = 3840; 
        if B > 640, Kb = 10;
        elseif B > 560, Kb = 9;
        elseif B > 192, Kb = 8;
        else, Kb = 6;
        end
    end

    % --- Determine number of code blocks (C) ---
    % L: number of CRC bit
    % C: number of Code block
    % B: number of Code block + CRC bit
    % Bd: Total bit after segmentation

    if B <= Kcb
        % No segmentation needed
        C = 1; Bd = B;
    else
        % Segmentation required
        L = 24; 
        C = ceil(B / (Kcb - L));
        Bd = B + C * L;
    end


    % Kd: Bits per block after CRC attachment
    % K: Information bits per code block
    % F: Number of filter bit added

    % Bits per block before CRC attachment
    cbz = ceil(B / C);  
    % Bits per block after CRC attachment
    Kd  = ceil(Bd / C); 

    % --- Choose lifting size (Zc) ---
    % Find smallest Zc from the standard list such that the code can contain Kd bits.
    Zlist = [2:16 18:2:32 36:4:64 72:8:128 144:16:256 288:32:384];
    Zc = min(Zlist(Kb * Zlist >= Kd));
    
    % --- Calculate filler bits (F) ---
    if bgn == 1
        K = 22 * Zc; 
    else % bgn == 2
        K = 10 * Zc; 
    end
    F = K - Kd;  

    % --- Segmentation and CRC attachment ---
    if C == 1
        % If only one block, no internal CRC is added here
        cbCRC = in(:);
    else
        cbCRC = zeros(Kd, C);   % Each column = one code block
        s = 1;                  % Input bit pointer

        for r = 1:C
            % Number of bits to copy
            if s + cbz - 1 <= B
                data = in(s:s+cbz-1);
            else
                % Zero padding if input bits run out
                data = [in(s:B); zeros(cbz - (B-s+1),1)];
            end
            s = s + cbz;

            % --- Attach CRC24B ---
            encoded_block = createCRC(data.', '24B');   
            cbCRC(:,r) = encoded_block(:);
        end
    end

    cbs = [cbCRC; -1 * ones(F, C)];
end