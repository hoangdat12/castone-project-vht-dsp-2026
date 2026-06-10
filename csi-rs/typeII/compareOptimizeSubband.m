%% Changeable Parameters
% These below parameters can be change to expand these situation comparision 

% -----------------------------------------------------------
% This comparision find the threadhold of number subband that 
%   enhanced Type II has fewer bits reported than Type II standard
% In this example comparision, it will run from 1 to 100 subbands.
% -----------------------------------------------------------
maxNumberOfSubband = 5;

% -----------------------------------------------------------
% Type II Standard support L = {2, 3, 4}.
% Type II Enhanced support L = {2, 4, 6}.
% In this comparision, we just consider two case L = 2 and L = 4.
% -----------------------------------------------------------
L_cases = [2, 4];

% -----------------------------------------------------------
% Type II Standard support v = {1, 2} because of the weitghed report.
% Type II Standard support v = {1, 2, 3, 4} 
% In this comparision, we just consider two case v = 1 and v = 2
% -----------------------------------------------------------
V_case = [1, 2];

% -----------------------------------------------------------
% The limitation of the all_cases variable below.
% -----------------------------------------------------------
numberOfPorts = 16;

% -----------------------------------------------------------
% The parameter Mv depend on the paramCombination in the RRC config
% In this comparision, we just compare for L = 2 and L = 4
% The range values of paramCombination = {1, 2, 3, 4, 5, 6}
%   + L = 2 => paramCombination = {1, 2}
%   + L = 4 => paramCombination = {3, 4, 5, 6}
% -----------------------------------------------------------
posibleL = [2, 4];
posiblePCombination = {[1, 2], [3, 4, 5, 6]};
paramCombinationRef = containers.Map(posibleL, posiblePCombination);

% -----------------------------------------------------------
% The folder will save the output table.
% Each file of the folder is the comparision case between two Type.
% -----------------------------------------------------------
outputFolder = 'compareTables';

% -----------------------------------------------------------
% Custom Parameters for Type II Standard.
% All most situation, the number of bit reported 
%   of Type II Standard always greater than Enhanced Type II.
% -----------------------------------------------------------
% Npsk = {4, 8}
Npsk = 4;
% Npsk = {1, ..., 2L - 1}
Ml = 3;
subbandAmplitude = false;

% -----------------------------------------------------------
% The posibility usecases
% -----------------------------------------------------------
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

% -----------------------------------------------------------
% Compute the number of Ports will be produce base on the numberOfPorts parameter.
% The range will last from 4 to numberOfPorts.
% -----------------------------------------------------------
actualPorts = arrayfun(@(c) 2 * c.N1 * c.N2, all_cases);
cases = all_cases(actualPorts <= numberOfPorts);

% -----------------------------------------------------------
% Export the comparision table here.
% -----------------------------------------------------------
createComparisionTable( ...
    outputFolder, cases, maxNumberOfSubband, ...
    L_cases, V_case, paramCombinationRef, ...
    Ml, Npsk, subbandAmplitude ...
)


%% HELPER FUNCTION

% -----------------------------------------------------------
% This function use to compare the optimize number of subbands
% Compare between Type II standard and Enhanced Type II
% -----------------------------------------------------------
function [numberOfBitsReported, totalBitsStandardReported] = ...
computeReportedBits(...
    L, nLayers, numberOfSubband, paramCombination, ... 
    N1, N2, O1, O2, Ml, Npsk, subbandAmplitude ...
)

    R = 1;
    % Compute the total bits for Type II Standard.
    totalBitsStandardReported = ...
    computeTotalBitReportedForTypeIIStandard( ...
        L, nLayers, numberOfSubband, ...
        N1, N2, O1, O2, Ml, Npsk, subbandAmplitude ...
    );

    % Compute Mv value.
    [~, Pv, ~] = gettingParamsFromParamCombination(paramCombination, nLayers);
    Mv = ceil(Pv * numberOfSubband/R);

    % Compute the total bits for Type II Enhanced.
    numberOfBitsReported = ...
    computeTotalBitReportedForTypeIIEnhanced( ...
        L, nLayers, numberOfSubband, ...
        Mv, N1, N2, O1, O2...
    );
end

% ------------------------------------------------------------
% Type II standard just only support two layers because of it's complex reported PMI
% + i1
%   1 Layer: [i11, i12, i13, i141]
%   2 Layers: [i11, i12, i131, i141, i132, i142]
% + i2
%   1 Layer: [i21, i22]
%   2 Layer: [i211, i212, i221, i222]
% ------------------------------------------------------------
function numberOfBitsReported = ...
computeTotalBitReportedForTypeIIStandard(...
    L, nLayers, numberOfSubband, N1, N2, O1, O2, Ml, Npsk, subbandAmplitude...
)
    
    % i11 just only contains two values [q1 q2] for all cases.
    % q1 = {0, 1, ... O1 - 1}.
    % q2 = {0, 1, ... O2 - 1}.
    % Maximum bits = log2(O2) + log2(O1).
    lengthOfI11 = ceil(log2(O1)) + ceil(log2(O2));

    % i12 just only contains one value to compute n1, n2.
    % i2 ∈ {0, 1, ..., C(N1*N2, L) - 1}.
    % where:
    %   N1*N2 : total number of available beams / ports.
    %   L     : number of selected beams / ports.
    maxI12Values = nchoosek(N1*N2, L);  
    lengthOfI12 = ceil(log2(maxI12Values));


    % i13 contains one values for each layer. Total length = nLayers x 1.
    % i13 = {0, 1, ..., 2L - 1}.
    lengthOfI13 = nLayers * ceil(log2(2*L));

    % i14 contains 2L values for each layer
    % Because of compression mechanism. The strongest coefficient is not reported
    % i14 = {0, 1, ..., 7}
    % The length of i14 = nLayers x (2L - 1) x log2(8) values.
    lengthOfI14 = nLayers * (2*L - 1) * ceil(log2(8));

    % K2 param is the maximum values reported for i21 and i22
    if L == 2 || L == 3
        K2 = 4;
    elseif L == 4
        K2 = 6;
    else 
        warning("The Type II Standard just only support L = {2, 3, 4} layers");
    end
    
    % i21 and i22 has the different number of elements reported
    % In this case, we use the maximum for comparision.
    % The total reported values = K2 x numberOfSubband x nLayers
    % The total bit of i21 and i22 depend on the subbandAmplitude in the RRC config

    if subbandAmplitude
        % The high resolution bit.
        % With min(Ml, K2) - 1 parameters will be reported in {0, 1, ... Npsk - 1}.
        countHigh = min(Ml, K2) - 1;
        lenI21High = countHigh * numberOfSubband * nLayers * ceil(log2(Npsk));
        
        % The low resolution bit.
        % With Ml min(Ml, K2) parameters will be reported in {0, 1, ... 3}.
        countLow  = Ml - min(Ml, K2);
        lenI21Low  = countLow  * numberOfSubband * nLayers * 2; 
        
        lengthOfI21 = lenI21High + lenI21Low;

        % In the case subbandAmplitude = true
        % The number of reported element is min(Ml, K2) - 1.
        countAmp = min(Ml, K2) - 1;
        lengthOfI22 = countAmp * numberOfSubband * nLayers * 1; 
    else
        % In the case subbandAmplitude = true.
        % The number of i21 elements is Ml.
        % i22 is not reported and default = 1.
        countAll = Ml;
        lengthOfI21 = countAll * numberOfSubband * nLayers * ceil(log2(Npsk));
        
        lengthOfI22 = 0;
    end
    

    numberOfBitsReported = lengthOfI11 + lengthOfI12 + ...
                           lengthOfI13 + lengthOfI14 + ...
                           lengthOfI21 + lengthOfI22;
end


% ------------------------------------------------------------
% Type II Enhanced support up to four layers because it takes advantaged of IDFT
% + i1 indices (layer-dependent)
%   ν = 1: [ i1,1  i1,2  i1,5  i1,6,1  i1,7,1  i1,8,1 ]
%   ν = 2: [ i1,1  i1,2  i1,5  i1,6,1  i1,7,1  i1,8,1  i1,6,2  i1,7,2  i1,8,2 ]
%   ν = 3: [ i1,1  i1,2  i1,5  i1,6,1  i1,7,1  i1,8,1  ...
%            i1,6,2  i1,7,2  i1,8,2  i1,6,3  i1,7,3  i1,8,3 ]
%   ν = 4: [ i1,1  i1,2  i1,5  i1,6,1  i1,7,1  i1,8,1  ...
%            i1,6,2  i1,7,2  i1,8,2  i1,6,3  i1,7,3  i1,8,3  i1,6,4  i1,7,4  i1,8,4 ]
% + i2 indices (layer-dependent)
%   ν = 1: [ i2,3,1  i2,4,1  i2,5,1 ]
%   ν = 2: [ i2,3,1  i2,4,1  i2,5,1  i2,3,2  i2,4,2  i2,5,2 ]
%   ν = 3: [ i2,3,1  i2,4,1  i2,5,1  ...
%            i2,3,2  i2,4,2  i2,5,2  i2,3,3  i2,4,3  i2,5,3 ]
%   ν = 4: [ i2,3,1  i2,4,1  i2,5,1  ...
%            i2,3,2  i2,4,2  i2,5,2  i2,3,3  i2,4,3  i2,5,3  i2,3,4  i2,4,4  i2,5,4 ]
% ------------------------------------------------------------
function numberOfBitsReported = ...
    computeTotalBitReportedForTypeIIEnhanced(L, nLayers, numberOfSubband, Mv, N1, N2, O1, O2)
    
    % i11 just only contains two values [q1 q2] for all cases.
    % q1 = {0, 1, ... O1 - 1}.
    % q2 = {0, 1, ... O2 - 1}.
    % Maximum bits = log2(O2) + log2(O1).
    lengthOfI11 = ceil(log2(O1)) + ceil(log2(O2));

    % i12 just only contains one value to compute n1, n2.
    % i2 ∈ {0, 1, ..., C(N1*N2, L) - 1}.
    % where:
    %   N1*N2 : total number of available beams / ports.
    %   L     : number of selected beams / ports.
    K = nchoosek(N1*N2, L);  
    lengthOfI12 = ceil(log2(K));

    % i15 contains one values for all case. 
    % i15 is reported in case N3 > 19. The default value = 0 if N3 < 19.
    % It use to identify the M_intial value.
    % i15 = {0, 1, ... Mv - 1}
    if numberOfSubband < 19
        lengthOfI15 = 0;
    else 
        lengthOfI15 = 1 * ceil(log2(Mv));
    end

    % It use to identify n_3_l.
    % i16 contains one values for each layers. 
    % The length of I16 = 1 x nLayers.
    %   N3 <= 19 i16 = {0 ... C(N3-1, Mv-1) - 1}
    %   N3 > 19 i16 = {0 ... C(2*Mv-1, Mv-1) - 1}
    if numberOfSubband <= 19
        maxI16Values = nchoosek(numberOfSubband - 1, Mv - 1); 
    else   
        maxI16Values = nchoosek(2 * Mv - 1, Mv - 1);
    end
    lengthOfI16 = nLayers * ceil(log2(maxI16Values));

    % i17 is a bitmap. 
    % It's acting like a map to identify number of params reported at i2.
    % The length of I17 = nLayers x 2 x L x Mv.
    % i17 = {0, 1}
    lengthOfI17 = nLayers * 2*L*Mv * ceil(log2(2));

    % i18 is the index of strongest coefficient. 
    % i18 has one value for each layer.
    % The length of i18 = nLayers x 1.
    % i18 = {0, 1, ... 2L - 1}.
    lengthOfI18 = nLayers * ceil(log2(2*L));

    % Because the strongest coefficient is not reported. 
    % The number of bits reported for each layer in case i2 reduce one.
    % Type II enhanced use IDFT to compress the report. 
    % i2 is not report by number of subband. It report by Mv parameters.
    
    % i23 is a wideband amplitude. 
    % It has two elements for each poralization.
    % Each layer has it own i23 value.
    % The length of i23 = nLayers x 2.
    % i23 = {0, 1, ..., 15}
    lengthOfI23 = nLayers * 2 * ceil(log2(16));

    % i24 is a subband amplitude.
    % It has Mv - 1 elements for each layers.
    % The length of i24 = nLayers x (Mv - 1);
    % i23 = {0, 1, ..., 7}
    lengthOfI24 = nLayers * (Mv - 1) * ceil(log2(8));

    % i24 is a subband phase.
    % It has Mv - 1 elements for each layers.
    % The length of i25 = nLayers x (Mv - 1);
    % i25 = {0, 1, ..., 15}
    lengthOfI25 = nLayers * (Mv - 1) * ceil(log2(16));

    numberOfBitsReported = lengthOfI11 + lengthOfI12 + ...
                           lengthOfI15 + lengthOfI16 + ...
                           lengthOfI17 + lengthOfI18 + ...
                           lengthOfI23 + lengthOfI24 + lengthOfI25;
end

% -----------------------------------------------------------
% This function use to mapping from paramCombination to Mv
% -----------------------------------------------------------
function [L, Pv, Beta] = gettingParamsFromParamCombination(paramCombination, nLayers)
    % Validate Input
    if ~isscalar(paramCombination) || paramCombination < 1 || paramCombination > 8
        error('paramCombination phải là số nguyên từ 1 đến 8.');
    end
    
    if ~isscalar(nLayers) || nLayers < 1 || nLayers > 4
        error('nLayers (Rank) phải là số nguyên từ 1 đến 4.');
    end

    % 2. Table 5.2.2.2.5-1 
    % Column L
    L_table = [2; 2; 4; 4; 4; 4; 6; 6];
    
    % Column Beta
    Beta_table = [1/4; 1/2; 1/4; 1/2; 3/4; 1/2; 1/2; 3/4];
    
    % Column pv with v = {1, 2}
    Pv_layers12 = [1/4; 1/4; 1/4; 1/4; 1/4; 1/2; 1/4; 1/4];
    
    % Column pv with v = {3, 4}
    Pv_layers34 = [1/8; 1/8; 1/8; 1/8; 1/4; 1/4; NaN; NaN];

    % Extract L and Beta 
    L = L_table(paramCombination);
    Beta = Beta_table(paramCombination);

    % Extract Pv based on nLayers value.
    if nLayers <= 2
        Pv = Pv_layers12(paramCombination);
    else
        Pv = Pv_layers34(paramCombination);
        
        if isnan(Pv)
            error('Cấu hình paramCombination = %d không hỗ trợ cho nLayers = %d (Rank > 2).', ...
                  paramCombination, nLayers);
        end
    end
end

% -----------------------------------------------------------
% This function use to handle logic compare
% -----------------------------------------------------------
function createComparisionTable( ...
    outputFolder, cases, maxNumberOfSubband, ...
    L_cases, V_case, paramCombinationRef, ...
    Ml, Npsk, subbandAmplitude ...
)
    % Check output folder
    if exist(outputFolder, 'dir')
        % If folder exists -> Clear existing files
        fprintf('Directory "%s" exists. Clearing old data...\n', outputFolder);
        
        filesToDelete = fullfile(outputFolder, '*');
        delete(filesToDelete); 
        
        fprintf('--> Directory cleaned.\n');
    else
        % If folder does not exist -> Create new
        mkdir(outputFolder);
        fprintf('Created new directory: %s\n', outputFolder);
    end

    % File Export Logic
    for caseIdx = 1:length(cases)
        
        currentConfig = cases(caseIdx);
        N1 = currentConfig.N1;
        N2 = currentConfig.N2;
        O1 = currentConfig.O1;
        O2 = currentConfig.O2;
        numPorts = 2 * N1 * N2; 
        mode = currentConfig.mode;
        
        % Generate file name and full path
        fileName = sprintf('Result_Case%d_%dPorts_Mode%d.txt', caseIdx, numPorts, mode);
        fullPath = fullfile(outputFolder, fileName); 
        
        fid = fopen(fullPath, 'w');
        
        if fid == -1
            error('Cannot create file at path: %s', fullPath);
        end
        
        % Write Header
        fprintf(fid, '=========================================================================\n');
        fprintf(fid, 'CASE %d: Ports=%d | N1=%d, N2=%d, O1=%d, O2=%d | Mode=%d\n', ...
                caseIdx, numPorts, N1, N2, O1, O2, mode);
        fprintf(fid, '=========================================================================\n');
        fprintf(fid, '| %-4s | %-4s | %-10s | %-10s | %-15s | %-15s |\n', ...
            'L', 'v', 'Subband', 'ParamComb', 'Bits(Enhanced)', 'Bits(Standard)');
        fprintf(fid, '|%s|\n', repmat('-', 1, 75));

        for numberOfSubband = 1:maxNumberOfSubband
            for l_idx = 1:length(L_cases)
                for v_idx = 1:length(V_case)
                    L = L_cases(l_idx);
                    nLayers = V_case(v_idx);

                    % --- FILTER INVALID CASES ---
                    
                    % 1. Mathematical Constraint: Cannot select L beams if L > Total Spatial Beams (N1*N2)
                    if L > N1 * N2
                        continue; 
                    end
                    
                    % According to TS 38.214, if P_CSI-RS = 4 (N1*N2 = 2), L must be 2.
                    % If L is not 2 for a 4-port config, it is invalid.
                    if (numPorts == 4) && (L ~= 2)
                        continue; 
                    end
                    
                    % ----------------------------------------------------

                    if isKey(paramCombinationRef, L)
                        pcList = paramCombinationRef(L);
                        
                        for pcIdx = 1:length(pcList)
                            paramCombination = pcList(pcIdx);
                            
                            % Compute bits
                            [bitsEnhanced, bitsStandard] = ...
                            computeReportedBits(...
                                L, nLayers, numberOfSubband, paramCombination, ...
                                N1, N2, O1, O2, Ml, Npsk, subbandAmplitude...
                            );
                            
                            % Write valid row to file
                            fprintf(fid, '| %-4d | %-4d | %-10d | %-10d | %-15d | %-15d |\n', ...
                                L, nLayers, numberOfSubband, paramCombination, bitsEnhanced, bitsStandard);
                        end
                    end
                end
            end
        end
        
        fprintf(fid, '|%s|\n', repmat('-', 1, 75));
        fclose(fid);
    end

    fprintf('Done! New data has been updated in "%s".\n', outputFolder);
end