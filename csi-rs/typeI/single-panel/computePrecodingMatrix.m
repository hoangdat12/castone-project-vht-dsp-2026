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
numberOfPorts = 32;
folderName = 'pmiData';

%% Coding Logics

% ---------------------------------------------------------
% Table 5.2.2.2.1-2: Supported configurations of (N1 N2) and (O1 O2)
% Every row in that table will have two case - codebookMode = 1, 2
% ---------------------------------------------------------
all_cases = [
    % 4 Ports
    struct('N1',2,'N2',1,'O1',4,'O2',1,'mode',1)
    struct('N1',2,'N2',1,'O1',4,'O2',1,'mode',2)
    
    % 8 Ports
    struct('N1',2,'N2',2,'O1',4,'O2',4,'mode',1) 
    struct('N1',2,'N2',2,'O1',4,'O2',4,'mode',2)
    struct('N1',4,'N2',1,'O1',4,'O2',1,'mode',1)
    struct('N1',4,'N2',1,'O1',4,'O2',1,'mode',2)
    
    % 12 Ports
    struct('N1',3,'N2',2,'O1',4,'O2',4,'mode',1) 
    struct('N1',3,'N2',2,'O1',4,'O2',4,'mode',2)
    struct('N1',6,'N2',1,'O1',4,'O2',1,'mode',1)
    struct('N1',6,'N2',1,'O1',4,'O2',1,'mode',2)
    
    % 16 Ports
    struct('N1',4,'N2',2,'O1',4,'O2',4,'mode',1)
    struct('N1',4,'N2',2,'O1',4,'O2',4,'mode',2)
    struct('N1',8,'N2',1,'O1',4,'O2',1,'mode',1)
    struct('N1',8,'N2',1,'O1',4,'O2',1,'mode',2)
    
    % 24 Ports
    struct('N1',4,'N2',3,'O1',4,'O2',4,'mode',1) 
    struct('N1',4,'N2',3,'O1',4,'O2',4,'mode',2)
    struct('N1',6,'N2',2,'O1',4,'O2',4,'mode',1)
    struct('N1',6,'N2',2,'O1',4,'O2',4,'mode',2)
    struct('N1',12,'N2',1,'O1',4,'O2',1,'mode',1) 
    struct('N1',12,'N2',1,'O1',4,'O2',1,'mode',2)
    
    % 32 Ports
    struct('N1',4,'N2',4,'O1',4,'O2',4,'mode',1) 
    struct('N1',4,'N2',4,'O1',4,'O2',4,'mode',2)
    struct('N1',8,'N2',2,'O1',4,'O2',4,'mode',1) 
    struct('N1',8,'N2',2,'O1',4,'O2',4,'mode',2)
    struct('N1',16,'N2',1,'O1',4,'O2',1,'mode',1) 
    struct('N1',16,'N2',1,'O1',4,'O2',1,'mode',2)
];

% Compute the number of Ports will be produce base on the numberOfPorts parameter.
actualPorts = arrayfun(@(c) 2 * c.N1 * c.N2, all_cases);
cases = all_cases(actualPorts <= numberOfPorts);

% Loop from 1 to 4 layers
for nLayers = 1:numberOfLayers
    % Create Precoding Matrix Lists
    W = struct();

    for k = 1:length(cases)
        % get every case in of the PMI
        c = cases(k);

        % ---- number of ports ----
        port = 2 * c.N1 * c.N2;

        % ---- generate key ----
        key = sprintf('L%d_P%d_N1_%d_c%d', nLayers, port, c.N1, c.mode);

        % ---- generate precoder ----
        W.(key) = generatePrecodingMatrix( ...
            c.N1, c.N2, c.O1, c.O2, nLayers, c.mode);

        fileName = sprintf('Layer%d_Port%d_N1_%d_N2-%d_c%d.txt', nLayers, port, c.N1, c.N2, c.mode);    

        % Export data into txt file.
        exportData(nLayers, W, c, folderName, fileName);
    end
end


%% --------- Helper Function ------------
function cfg = getCfigVariable(N1, N2, O1, O2, codebookMode)
    cfg.CodebookConfig.N1 = N1;
    cfg.CodebookConfig.N2 = N2;
    cfg.CodebookConfig.O1 = O1;
    cfg.CodebookConfig.O2 = O2;
    cfg.CodebookConfig.nPorts = 2*N1*N2;
    cfg.CodebookConfig.codebookMode = codebookMode;
end

function W = generatePrecodingMatrix(N1, N2, O1, O2, nLayers, codebookMode)
    % Create lookup table
    [i11_lookup, i12_lookup, i13_lookup, i2_lookup] = lookupPMITable(N1, N2, O1, O2, nLayers, codebookMode);

    % Get total PMI. Because of lookup table [PMI_length x 1]
    totalPmi = length(i2_lookup);

    W = cell(totalPmi, 1);

    for pmi_value = 0:totalPmi-1
        % Matlab index start from 1.
        pmi_idx = pmi_value + 1;

        % Mapping from PMI to i11, i12, i2
        i11 = i11_lookup(pmi_idx);
        i12 = i12_lookup(pmi_idx);
        i13 = i13_lookup(pmi_idx);
        i2  = i2_lookup(pmi_idx);

        cfg = getCfigVariable(N1, N2, O1, O2, codebookMode);

        i1 = {i11, i12, i13};

        W{pmi_idx}.matrix = generateTypeISinglePanelPrecoder(cfg, nLayers, i1, i2);
        W{pmi_idx}.i11 = i11;
        W{pmi_idx}.i12 = i12;
        W{pmi_idx}.i13 = i13;
        W{pmi_idx}.i2  = i2;
    end
end

function exportData(nLayers, W, c, folderName, fileName)

    % Create folder
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    all_cases_file = fullfile(folderName, fileName);
    fid = fopen(all_cases_file, 'w');
    if fid == -1
        error('Không thể mở file để ghi: %s', all_cases_file);
    end

    % ---- Có i13 hay không ----
    hasI13 = (nLayers >= 2);

    % ---- Thông tin case ----
    port = 2 * c.N1 * c.N2;
    key  = sprintf('L%d_P%d_N1_%d_c%d', nLayers, port, c.N1, c.mode);

    if ~isfield(W, key)
        fclose(fid);
        return;
    end

    pmiCell = W.(key);

    % ---- Vòng lặp xuất Data chuẩn hóa cho prepareData ----
    for pmiIdx = 1:length(pmiCell)

        entry  = pmiCell{pmiIdx};
        matrix = entry.matrix;

        i11 = entry.i11;
        i12 = entry.i12;
        i2  = entry.i2;

        % 1. Ghi dòng Info (Hàm prepareData sẽ gán dòng này vào pool_info)
        if hasI13
            i13 = entry.i13;
            fprintf(fid, 'PMI_Index: %d, i11: %d, i12: %d, i13: %d, i2: %d\n', pmiIdx-1, i11, i12, i13, i2);
        else
            fprintf(fid, 'PMI_Index: %d, i11: %d, i12: %d, i2: %d\n', pmiIdx-1, i11, i12, i2);
        end

        [numPorts, numL] = size(matrix);

        % 2. Ghi nPort dòng ma trận (Hàm prepareData sẽ dùng vòng for đọc số dòng này)
        for p = 1:numPorts
            for L = 1:numL
                val = matrix(p, L);
                
                % Định dạng số phức KHÔNG CÓ KHOẢNG TRẮNG ở giữa (vd: 0.123456+0.123456i) 
                % Độ chính xác .6f để giữ nguyên năng lượng Beamforming
                fprintf(fid, '%.6f%+.6fi', real(val), imag(val));

                % Cách các Layer bằng một khoảng tab (dễ nhìn và chuẩn cho str2num)
                if L < numL
                    fprintf(fid, '\t');
                end
            end
            
            % Xuống dòng sau khi ghi xong 1 hàng của ma trận
            fprintf(fid, '\n');
        end
        
    end

    fclose(fid);
    fprintf('Đã xuất file format MỚI thành công: %s\n', all_cases_file);
end

% function exportData(nLayers, W, c, folderName, fileName)

%     % Create folder
%     if ~exist(folderName, 'dir')
%         mkdir(folderName);
%     end

%     all_cases_file = fullfile(folderName, fileName);
%     fid = fopen(all_cases_file, 'w');
%     if fid == -1
%         error('Không thể mở file để ghi: %s', all_cases_file);
%     end

%     fprintf(fid, 'TỔNG HỢP PRECODING MATRICES - LAYER %d\n', nLayers);
%     fprintf(fid, '============================================================\n\n');

%     % ---- Có i13 hay không ----
%     hasI13 = (nLayers >= 2);

%     % ---- Thông tin case ----
%     port = 2 * c.N1 * c.N2;
%     key  = sprintf('L%d_P%d_N1_%d_c%d', nLayers, port, c.N1, c.mode);

%     if ~isfield(W, key)
%         fclose(fid);
%         return;
%     end

%     pmiCell = W.(key);

%     % ---- Header case ----
%     fprintf(fid, ...
%         'CASE: %d Layers - %d Ports - N1 = %d N2 = %d O1 = %d O2 = %d Mode = %d\n', ...
%         nLayers, port, c.N1, c.N2, c.O1, c.O2, c.mode);

%     fprintf(fid, '\n------------------------- PARAMETERS -----------------------\n');

%     [i11_max, i12_max, i13_max, i2_max] = ...
%         findRangeValues(c.N1, c.N2, c.O1, c.O2, nLayers, c.mode);

%     rI11 = 0:i11_max;
%     rI12 = 0:i12_max;
%     rI2  = 0:i2_max;

%     if i13_max >= 0
%         rI13 = 0:i13_max;
%     else
%         rI13 = [];
%     end

%     printSet(fid, 'i11', rI11);
%     printSet(fid, 'i12', rI12);

%     if ~isempty(rI13)
%         printSet(fid, 'i13', rI13);
%     end

%     printSet(fid, 'i2', rI2);

%     fprintf(fid, '\n------------------------- PMI TABLES -----------------------\n\n');


%     % ---- Header bảng ----
%     if hasI13
%         fprintf(fid, '%-6s %-4s %-4s %-4s %-4s | %s\n', ...
%                 'PMI','i11','i12','i13','i2','W');
%     else
%         fprintf(fid, '%-6s %-4s %-4s %-4s | %s\n', ...
%                 'PMI','i11','i12','i2','W');
%     end

%     fprintf(fid, '------------------------------------------------------------\n');

%     % ---- Loop từng PMI ----
%     for pmiIdx = 1:length(pmiCell)

%         entry  = pmiCell{pmiIdx};
%         matrix = entry.matrix;

%         i11 = entry.i11;
%         i12 = entry.i12;
%         i2  = entry.i2;

%         if hasI13
%             i13 = entry.i13;
%         end

%         [numPorts, numL] = size(matrix);

%         for p = 1:numPorts

%             if p == 1
%                 if hasI13
%                     fprintf(fid, '%-6d %-4d %-4d %-4d %-4d |', ...
%                             pmiIdx-1, i11, i12, i13, i2);
%                 else
%                     fprintf(fid, '%-6d %-4d %-4d %-4d |', ...
%                             pmiIdx-1, i11, i12, i2);
%                 end
%             else
%                 if hasI13
%                     fprintf(fid, '%-6s %-4s %-4s %-4s %-4s |', ...
%                             '', '', '', '', '');
%                 else
%                     fprintf(fid, '%-6s %-4s %-4s %-4s |', ...
%                             '', '', '', '');
%                 end
%             end

%             for L = 1:numL
%                 val = matrix(p, L);
%                 fprintf(fid, ' %8.4f %+8.4fi', real(val), imag(val));

%                 if L < numL
%                     fprintf(fid, ',');
%                 end
%             end

%             fprintf(fid, '\n');
%         end

%         fprintf(fid, '\n');
%     end

%     fclose(fid);
%     fprintf('Đã xuất file: %s\n', all_cases_file);
% end

% function printSet(fid, name, vec)
%     fprintf(fid, '%s = {', name);
%     for k = 1:length(vec)
%         if k < length(vec)
%             fprintf(fid, '%d, ', vec(k));
%         else
%             fprintf(fid, '%d', vec(k));
%         end
%     end
%     fprintf(fid, '}\n');
% end


