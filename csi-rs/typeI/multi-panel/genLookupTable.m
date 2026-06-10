%% ================== TEST CASE ==================
N1 = 2; N2 = 1; O1 = 4; O2 = 1; Ng = 2; nLayers = 1; codebookMode = 2;

%% ============== GENERATE LOOKUP ==============
% Goi ham chinh
[i11_lookup, i12_lookup, i13_lookup, ...
 i14_lookup, i20_lookup, i2x_lookup] = ...
 lookupPMITable(N1, N2, O1, O2, nLayers, Ng, codebookMode);

N = length(i11_lookup);

%% ================== EXPORT PMI TABLE ==================
filename = 'PMI_table.txt';
fid = fopen(filename, 'w');

% QUAN TRONG: Lay so luong cot thuc te
num_col_i14 = size(i14_lookup, 2); 
num_col_i2x = size(i2x_lookup, 2);

% -------- Header --------
fprintf(fid, ' %4s | %4s | %4s', 'i11', 'i12', 'i13');

for q = 1:num_col_i14
    fprintf(fid, ' | %7s', sprintf('i14_q%d', q));
end

fprintf(fid, ' | %4s', 'i20');

for x = 1:num_col_i2x
    fprintf(fid, ' | %7s', sprintf('i2x_%d', x));
end
fprintf(fid, '\n');

% Tinh toan do dai dong ke ngang
line_len = 18 + (10 * num_col_i14) + 7 + (10 * num_col_i2x);
fprintf(fid, '%s\n', repmat('-', 1, line_len));

% -------- Data --------
for n = 1:N
    % In cac chi so scalar
    fprintf(fid, ' %4d | %4d | %4d', ...
        i11_lookup(n), i12_lookup(n), i13_lookup(n));

    % In cac cot cua i14
    for q = 1:num_col_i14
        fprintf(fid, ' | %7d', i14_lookup(n,q));
    end

    % In chi so i20
    fprintf(fid, ' | %4d', i20_lookup(n));

    % In cac cot cua i2x
    for x = 1:num_col_i2x
        fprintf(fid, ' | %7d', i2x_lookup(n,x));
    end

    fprintf(fid, '\n');
end

fclose(fid);
fprintf('PMI table generated: %d rows. Exported to %s\n', N, filename);