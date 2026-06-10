function W_vsa = vsa_normalize_matrix(varargin)
    % 1. Ghép tất cả các ma trận W đầu vào
    W_total = [];
    for i = 1:length(varargin)
        W_total = [W_total, varargin{i}];
    end
    
    % 2. Tìm phần tử có biên độ LỚN NHẤT (max|W|) theo tài liệu Keysight
    max_mag = max(abs(W_total(:)));
    
    % 3. Lấy góc pha của điểm quy chiếu (Mặc định Port 0, Ch 1)
    W_ref = W_total(1, 1);
    phase_ref = angle(W_ref);
    
    % 4. THỰC HIỆN CHUẨN HÓA
    % - Xoay pha: nhân với exp(-1i * phase_ref)
    % - Chuẩn biên độ: chia cho max_mag
    W_norm = (W_total .* exp(-1i * phase_ref)) ./ max_mag;
    
    % 5. Chuyển vị để khớp giao diện ngang của VSA
    W_vsa = W_norm.';
    
    % --- IN RA BẢNG ---
    fprintf('\n=== MA TRAN BEAM WEIGHTS CHUAN KEYSIGHT VSA ===\n');
    fprintf('Peak Magnitude (max|W|) = %.4f\n\n', max_mag);
    fprintf('%-20s', 'Name');
    for col = 1:size(W_vsa, 2)
        fprintf('Ch%-14d', col);
    end
    fprintf('\n');
    for row = 1:size(W_vsa, 1)
        fprintf('PDSCH_DMRS_Port%-5d', row - 1);
        for col = 1:size(W_vsa, 2)
            val = W_vsa(row, col);
            if imag(val) >= 0
                fprintf('%6.2f + j%-7.2f', real(val), imag(val));
            else
                fprintf('%6.2f - j%-7.2f', real(val), abs(imag(val)));
            end
        end
        fprintf('\n');
    end
    fprintf('===============================================\n\n');
end