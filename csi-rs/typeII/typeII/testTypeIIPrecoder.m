% cfg = struct();

% cfg.CodebookConfig.N1 = 4;
% cfg.CodebookConfig.N2 = 2;
% cfg.CodebookConfig.O1 = 4;
% cfg.CodebookConfig.O2 = 4;

% cfg.CodebookConfig.NumberOfBeams = 4;     % L
% cfg.CodebookConfig.PhaseAlphabetSize = 8; % NPSK
% cfg.CodebookConfig.SubbandAmplitude = true;
% cfg.CodebookConfig.numLayers = 2;         % nLayers

% i11 = [2, 1];
% i12 = [2];
% i13 = [3, 1];
% i14 = [4, 6, 5, 0, 2, 3, 1 ; 3, 2, 4, 1, 5, 6, 0];
% i21 = [1, 3, 4, 2, 5, 7 ; 2, 0, 5, 1, 4, 6];
% i22 = [0, 1, 0, 1, 0 ; 1, 1, 0, 0, 1];

% i1 = {i11, i12, i13, i14};
% i2 = {i21, i22};

% W = generateTypeIIPrecoder(cfg, i1, i2);

%    0.0444 + 0.0728i   0.1286 + 0.0000i
%    0.0394 - 0.0317i   0.0369 - 0.1485i
%    0.0201 - 0.0142i  -0.1231 - 0.0588i
%   -0.0240 - 0.0689i  -0.0891 + 0.0615i
%    0.1114 - 0.0486i   0.0588 + 0.0909i
%   -0.0471 - 0.1029i   0.0768 - 0.0318i
%   -0.0645 + 0.0042i   0.0227 - 0.0604i
%   -0.0657 + 0.0426i  -0.0594 - 0.0738i
%   -0.0243 - 0.2789i   0.0000 + 0.1740i
%   -0.2855 - 0.0394i   0.1311 + 0.0789i
%   -0.1114 + 0.2144i   0.1552 - 0.0909i
%    0.1106 + 0.2035i  -0.0543 - 0.1905i
%   -0.1457 - 0.1516i  -0.0588 + 0.0909i
%   -0.1772 + 0.1215i   0.0492 + 0.1188i
%    0.0444 + 0.1616i   0.1513 - 0.0227i
%    0.1477 + 0.0657i   0.0072 - 0.1362i
%   -0.0243 - 0.0243i  -0.0643 - 0.0748i
%   -0.0317 + 0.0131i  -0.1024 + 0.0098i
%   -0.0000 + 0.0343i  -0.0302 + 0.1211i
%    0.0317 + 0.0131i   0.1090 + 0.0532i
%   -0.0243 + 0.0343i  -0.0984 + 0.0302i
%    0.0224 + 0.0356i  -0.0307 + 0.0937i
%    0.0415 - 0.0071i   0.0909 + 0.0804i
%    0.0093 - 0.0410i   0.1003 - 0.0742i
%   -0.0101 - 0.0243i   0.1070 - 0.0643i
%   -0.0263 + 0.0000i  -0.0394 - 0.1147i
%   -0.0101 + 0.0243i  -0.0984 - 0.0075i
%    0.0186 + 0.0186i  -0.0655 + 0.0793i
%   -0.0586 + 0.0000i  -0.0075 - 0.1211i
%   -0.0224 + 0.0542i  -0.1234 - 0.0184i
%    0.0415 + 0.0415i  -0.0482 + 0.0909i
%    0.0542 - 0.0224i   0.0445 + 0.0880i

%% Case 2
cfg = struct();

cfg.CodebookConfig.N1 = 4;
cfg.CodebookConfig.N2 = 1;
cfg.CodebookConfig.O1 = 4;
cfg.CodebookConfig.O2 = 1;

cfg.CodebookConfig.NumberOfBeams = 2;     % L = 4
cfg.CodebookConfig.PhaseAlphabetSize = 8; % NPSK = 8
cfg.CodebookConfig.SubbandAmplitude = true;
cfg.CodebookConfig.numLayers = 2;         % nLayers = 1

i11 = [3, 0]; 
i12 = 3; 
i13 = [3, 2]; 
i14 = [0, 2, 4;   % Layer 1
       7, 3, 6];  % Layer 2
i21 = [7, 7, 0;   % Layer 1
       1, 3, 7];  % Layer 2
i22 = [0, 1, 0;   % Layer 1
       1, 1, 1];  % Layer 2
i1 = {i11, i12, i13, i14};
i2 = {i21, i22};

% Gọi hàm tạo ma trận Precoder
W = generateTypeIIPrecoder(cfg, i1, i2);

% Hiển thị kết quả kiểm tra
disp('Ma trận Precoder W cho layer 1:');
disp(W);