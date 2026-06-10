function [txdata] = ofdmModulation(txdataF, NFFT)
    idx = 0;
    cp_samples0 = 176*NFFT/2048;
    cp_samples  = 144*NFFT/2048;
    mu = 1;
    for i=1:size(txdataF,2)
        tmp = ifft(txdataF(:, i),NFFT);
        if mod(i,7*2^mu) == 1
            txdata((idx + cp_samples0 + 1) : (idx + cp_samples0 + NFFT),1) = tmp;
            txdata((idx + 1): (idx + cp_samples0),1) = tmp((NFFT - cp_samples0 + 1):end);
            idx = idx + cp_samples0 + NFFT;
        else
            txdata((idx + cp_samples + 1) : (idx + cp_samples + NFFT),1) = tmp;
            txdata((idx + 1): (idx + cp_samples),1) = tmp((NFFT - cp_samples + 1):end);
            idx = idx + cp_samples + NFFT;
        end
    end
end