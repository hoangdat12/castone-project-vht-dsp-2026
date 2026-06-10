function outWaveform = ofdmModulationAndWaveformExport(frameGrid, fileName, W)
    NFFT       = 4096;
    numRe      = size(frameGrid, 1);
    numSymb    = size(frameGrid, 2);
    numTxPorts = size(W, 1);

    % OFDM modulate một lần — dùng lại cho mọi mức SNR
    txdata1 = [];
    for p = 1:numTxPorts
        txDataF_Port = [frameGrid(numRe/2+1:end, :, p); ...
                        zeros(NFFT - numRe, numSymb);   ...
                        frameGrid(1:numRe/2, :, p)];
        txdata1 = [txdata1, ofdmModulation(txDataF_Port, NFFT)];
    end
    fprintf('Kich thuoc sau OFDM (1 Frame) [Mau x Port]: %d x %d\n\n', size(txdata1));

    centerFreq = 0;
    nFrame     = 5;
    scs        = 30000;

    % =========================================================================
    % SWEEP SNR 10 → 30 dB, mỗi mức xuất 1 file riêng
    % =========================================================================
    snr_list = 15;  % [10, 15, 20, 25, 30]

    for k = 1:length(snr_list)
        snr_dB = snr_list(k);

        % Add noise riêng từng port
        txdata_noisy = zeros(size(txdata1));
        for p = 1:numTxPorts
            txdata_noisy(:,p) = awgn(txdata1(:,p), snr_dB, 'measured');
        end

        data_repeat = repmat(txdata_noisy, nFrame, 1);

        % Tên file: vd "output_SNR10dB.bin"
        [folder, name, ext] = fileparts(fileName);
        snrFileName = fullfile(folder, sprintf('%s_SNR%ddB%s', name, snr_dB, ext));

        savevsarecordingmulti(snrFileName, data_repeat, NFFT*scs, centerFreq, numTxPorts);
        fprintf('Da xuat: %s (SNR = %d dB)\n', snrFileName, snr_dB);
    end

    % Xuất thêm file sạch làm reference
    [folder, name, ext] = fileparts(fileName);
    cleanFileName = fullfile(folder, sprintf('%s_CLEAN%s', name, ext));
    data_clean = repmat(txdata1, nFrame, 1);
    savevsarecordingmulti(cleanFileName, data_clean, NFFT*scs, centerFreq, numTxPorts);
    fprintf('Da xuat file sach: %s\n', cleanFileName);

    % Output trả về là file sạch
    outWaveform = data_clean;
end