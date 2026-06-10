%% Parameters

% ---------------------------------------------------------
% Parameter Description:
% - numberOfLayers: Number of transmission layers. This parameter determines
%   how many layers will be processed and displayed.
% - numberOfPorts: Number of antenna ports. This parameter determines
%   which rows are selected from Table 5.2.2.2.1-2.
%   Examples:
%     + numberOfPorts = 12  -> Port set = [4, 8, 12]
%     + numberOfPorts = 32  -> Port set = [4, 8, 12, 16, 32]
% - folderName: Name of the output folder used to export data.
%   Inside this folder, one output file will be generated
%   for each transmission layer.
% ---------------------------------------------------------

numberOfLayers = 4;
numberOfPorts = 16;
folderName = 'pmiData';

%% Coding logic

% ---------------------------------------------------------
% Table 5.2.2.2.2-1: Supported configurations of (N1 N2) and (O1 O2)
% Every row in that table will have two case - codebookMode = 1, 2
% ---------------------------------------------------------
all_cases = [
    struct('Ng',2, 'N1',2, 'N2',1, 'O1',4, 'O2',1, 'mode',1)
    struct('Ng',2, 'N1',2, 'N2',1, 'O1',4, 'O2',1, 'mode',2)

    struct('Ng',2, 'N1',4, 'N2',1, 'O1',4, 'O2',1, 'mode',1)
    struct('Ng',2, 'N1',4, 'N2',1, 'O1',4, 'O2',1, 'mode',2)
    
    struct('Ng',4, 'N1',2, 'N2',1, 'O1',4, 'O2',1, 'mode',1)
    
    struct('Ng',2, 'N1',2, 'N2',2, 'O1',4, 'O2',4, 'mode',1)
    struct('Ng',2, 'N1',2, 'N2',2, 'O1',4, 'O2',4, 'mode',2)

    struct('Ng',2, 'N1',8, 'N2',1, 'O1',4, 'O2',1, 'mode',1)
    struct('Ng',2, 'N1',8, 'N2',1, 'O1',4, 'O2',1, 'mode',2)
    
    struct('Ng',4, 'N1',4, 'N2',1, 'O1',4, 'O2',1, 'mode',1)
    
    struct('Ng',2, 'N1',4, 'N2',2, 'O1',4, 'O2',4, 'mode',1)
    struct('Ng',2, 'N1',4, 'N2',2, 'O1',4, 'O2',4, 'mode',2)
    
    struct('Ng',4, 'N1',2, 'N2',2, 'O1',4, 'O2',4, 'mode',1)
];

% Compute the number of Ports will be produce base on the numberOfPorts parameter.
actualPorts = arrayfun(@(c) 2 * c.Ng * c.N1 * c.N2, all_cases);
cases = all_cases(actualPorts <= numberOfPorts);

% Loop from 1 to 4 layers
for nLayers = 1:numberOfLayers
    % Create Precoding Matrix Lists
    W = struct();

    for k = 1:length(cases)
        % get every case in of the PMI
        c = cases(k);

        % ---- number of ports ----
        port = 2 * c.Ng * c.N1 * c.N2;

        % The key to identify each values
        key = sprintf('L%d_P%d_Ng%d_N1%d_N2%d_Mode%d', ...
                      nLayers, port, c.Ng, c.N1, c.N2, c.mode);

        % Generate Precoding Matrix for each case in the table  5.2.2.2.2-1
        W.(key) = generatePrecodingMatrix( ...
            c.Ng, c.N1, c.N2, c.O1, c.O2, nLayers, c.mode);

        fileName = sprintf('Layer%d_Port%d_N1-%d_N2-%d_c%d', nLayers, port, c.N1, c.N2, c.mode);    

        % Export data into txt file.
        exportData(nLayers, W, c, folderName, fileName);
    end
end

%% ------------ HELPER FUNCTION --------------

function cfg = getCfigVariable(Ng, N1, N2, O1, O2, codebookMode)
    cfg.CodebookConfig.N1 = N1;
    cfg.CodebookConfig.N2 = N2;
    cfg.CodebookConfig.O1 = O1;
    cfg.CodebookConfig.O2 = O2;
    cfg.CodebookConfig.nPorts = 2*Ng*N1*N2;
    cfg.CodebookConfig.codebookMode = codebookMode;
end

function W = generatePrecodingMatrix(Ng, N1, N2, O1, O2, nLayers, codebookMode)
    % Create lookup table
    [i11_lookup, i12_lookup, i13_lookup, ...
    i14_lookup, i20_lookup, i2x_lookup] = ...
    lookupPMITable(N1, N2, O1, O2, nLayers, Ng, codebookMode);

    % Get total PMI. Because of lookup table [PMI_length x 1]
    totalPmi = length(i11_lookup);

    W = cell(totalPmi, 1);

    for pmi_value = 0:totalPmi-1

        % Matlab index start from 1
        pmi_idx = pmi_value + 1;

        % Because of i14_lookup and i2x_lookup contains value for i14q, q = 0, .. Ng - 1 
        num_col_i14 = size(i14_lookup, 2); 
        num_col_i2x = size(i2x_lookup, 2);

        i14 = zeros(1, num_col_i14); 
        i2x = zeros(1, num_col_i2x);

        for q = 1:num_col_i14
            i14(q) = i14_lookup(pmi_idx, q);
        end

        for x = 1:num_col_i2x
            i2x(x) = i2x_lookup(pmi_idx, x);
        end

        i11 = i11_lookup(pmi_idx);
        i12 = i12_lookup(pmi_idx);
        i13 = i13_lookup(pmi_idx);
        i20 = i20_lookup(pmi_idx);

        i1 = {i11, i12, i13, i14};
        i2 = [i20, i2x];
        cfg = getCfigVariable(Ng, N1, N2, O1, O2, codebookMode);

        % Compute Precoding Matrix
        W{pmi_idx}.matrix = generateTypeIMultiPanelPrecoder(cfg, nLayers, Ng, i1, i2);
        W{pmi_idx}.i11 = i11;
        W{pmi_idx}.i12 = i12;
        W{pmi_idx}.i13 = i13;
        W{pmi_idx}.i14 = i14;
        W{pmi_idx}.i2  = i2;
    end
end

function exportData(nLayers, W, c, folderName, fileName)

    % ---- 1. Create folder & Open File ----
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    all_cases_file = fullfile(folderName, fileName);
    fid = fopen(all_cases_file, 'w');
    if fid == -1
        error('Không thể mở file để ghi: %s', all_cases_file);
    end

    fprintf(fid, 'TỔNG HỢP MULTI-PANEL PRECODING MATRICES - LAYER %d\n', nLayers);
    fprintf(fid, '============================================================\n\n');

    % ---- Check Key ----
    port = 2 * c.Ng * c.N1 * c.N2;
    key = sprintf('L%d_P%d_Ng%d_N1%d_N2%d_Mode%d', ...
                  nLayers, port, c.Ng, c.N1, c.N2, c.mode);

    if ~isfield(W, key)
        fprintf(fid, 'Không tìm thấy dữ liệu cho Key: %s\n', key);
        fclose(fid);
        return;
    end

    pmiCell = W.(key);
    
    % ---- Parameters logic check ----
    sampleEntry = pmiCell{1};
    hasI13 = (isfield(sampleEntry, 'i13') && ~isempty(sampleEntry.i13));

    % ---- 2. Header Case Info ----
    fprintf(fid, ...
        'CASE: %d Layers - %d Ports - Ng=%d N1=%d N2=%d O1=%d O2=%d Mode=%d\n', ...
        nLayers, port, c.Ng, c.N1, c.N2, c.O1, c.O2, c.mode);

    % ---- 3. PARAMETERS SECTION ----
    fprintf(fid, '\n------------------------- PARAMETERS -----------------------\n');

    try
        % Trích xuất dữ liệu
        all_i11 = cellfun(@(x) x.i11, pmiCell);
        all_i12 = cellfun(@(x) x.i12, pmiCell);
        
        mat_i14 = cell2mat(cellfun(@(x) x.i14, pmiCell, 'UniformOutput', false));
        mat_i2  = cell2mat(cellfun(@(x) x.i2,  pmiCell, 'UniformOutput', false));

        % --- In Scalar Parameters ---
        printSet(fid, 'i11', unique(all_i11)');
        printSet(fid, 'i12', unique(all_i12)');
        
        if hasI13
             all_i13 = cellfun(@(x) x.i13, pmiCell);
             printSet(fid, 'i13', unique(all_i13)');
        end
        
        % --- In Vector i14 ---
        printSmartVector(fid, 'i14', mat_i14);

        % --- In Vector i2 (Layer 1 Mode 2) ---
        if c.mode == 2 && nLayers == 1
            i20_vals = unique(mat_i2(:, 1));      
            i2x_mat  = mat_i2(:, 2:end); 
            
            printSet(fid, 'i20', i20_vals');
            % Bây giờ i2x sẽ in ra dạng {0, 1} thay vì {[0 0]...}
            printSmartVector(fid, 'i2x', i2x_mat);
            
        else
            if c.mode == 1
                printSet(fid, 'i2', unique(mat_i2)');
            else
                printSmartVector(fid, 'i2', mat_i2);
            end
        end

    catch ME
        fprintf(fid, '(Error extracting parameters: %s)\n', ME.message);
    end

    fprintf(fid, '\n------------------------- PMI TABLES -----------------------\n\n');

    % ---- 4. Table Header ----
    str_i2_header = 'i2';
    if c.mode == 2 && nLayers == 1
        str_i2_header = 'i2 (i20, i2x)';
    end

    if hasI13
        fprintf(fid, '%-6s %-4s %-4s %-4s %-12s %-16s | %s\n', ...
                'PMI','i11','i12','i13','i14', str_i2_header, 'W Matrix (Real + Imag)');
    else
        fprintf(fid, '%-6s %-4s %-4s %-12s %-16s | %s\n', ...
                'PMI','i11','i12','i14', str_i2_header, 'W Matrix (Real + Imag)');
    end
    
    fprintf(fid, '%s\n', repmat('-', 1, 110)); 

    % ---- 5. Loop PMI ----
    for pmiIdx = 1:length(pmiCell)
        entry  = pmiCell{pmiIdx};
        matrix = entry.matrix;
        
        str_i14 = mat2str(entry.i14); 
        
        raw_i2 = entry.i2;
        if c.mode == 2 && nLayers == 1
            val_i20 = raw_i2(1);
            val_i2x = raw_i2(2:end);
            str_i2 = sprintf('%d, %s', val_i20, mat2str(val_i2x));
        elseif c.mode == 1
             str_i2 = mat2str(raw_i2(1));
        else
             str_i2 = mat2str(raw_i2(1:3));
        end

        [numPorts, numCols] = size(matrix);

        for p = 1:numPorts
            if p == 1
                if hasI13
                    fprintf(fid, '%-6d %-4d %-4d %-4d %-12s %-16s |', ...
                            pmiIdx-1, entry.i11, entry.i12, entry.i13, str_i14, str_i2);
                else
                    fprintf(fid, '%-6d %-4d %-4d %-12s %-16s |', ...
                            pmiIdx-1, entry.i11, entry.i12, str_i14, str_i2);
                end
            else
                if hasI13
                    fprintf(fid, '%-6s %-4s %-4s %-4s %-12s %-16s |', '', '', '', '', '', '');
                else
                    fprintf(fid, '%-6s %-4s %-4s %-12s %-16s |', '', '', '', '', '');
                end
            end

            for L = 1:numCols
                val = matrix(p, L);
                fprintf(fid, ' %8.4f %+8.4fi', real(val), imag(val));
                if L < numCols
                    fprintf(fid, ' ,');
                end
            end
            fprintf(fid, '\n');
        end
        fprintf(fid, '%s\n', repmat('.', 1, 110));
    end

    fclose(fid);
    fprintf('Đã xuất file: %s\n', all_cases_file);
end

% ---- Helper 1: In Set Scalar ----
function printSet(fid, name, vec)
    if isempty(vec)
        return;
    end
    fprintf(fid, '%s = {', name);
    fprintf(fid, '%d', vec(1));
    if length(vec) > 1
        fprintf(fid, ', %d', vec(2:end));
    end
    fprintf(fid, '}\n');
end

% ---- Helper 2: In Smart Vector (ĐÃ BỎ LIỆT KÊ) ----
function printSmartVector(fid, name, mat)
    if isempty(mat)
        return;
    end
    
    [~, width] = size(mat);
    unique_rows = unique(mat, 'rows');
    
    % TH1: Scalar (Width=1) -> In bình thường {0, 1}
    if width == 1
        printSet(fid, name, unique_rows');
        return;
    end
    
    % TH2: Vector (Width > 1) -> LUÔN LUÔN in dạng Tóm tắt (Summary)
    % Bỏ hoàn toàn logic in liệt kê {[0 0], [0 1]} để đảm bảo nhất quán
    unique_vals = unique(mat(:))';
    
    fprintf(fid, '%s = {', name); 
    fprintf(fid, '%d', unique_vals(1));
    if length(unique_vals) > 1
        fprintf(fid, ', %d', unique_vals(2:end));
    end
    % Thêm chú thích nhỏ
    fprintf(fid, '} (Indices for %d-element vector)\n', width);
end