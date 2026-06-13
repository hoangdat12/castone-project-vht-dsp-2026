% =========================================================================
% simulateRandomMUMIMOScheduling.m
% =========================================================================
clear; clc; close all;
setupPath();

nLayers      = 4;
numberOfUE   = 1000;

config.CodeBookConfig.N1     = 4;
config.CodeBookConfig.N2     = 4;
config.CodeBookConfig.cbMode = 1;
config.FileName = "Layer4_Port32_N1_4_N2-4_c1.txt";

[W_all, UE_Reported_Indices, totalPMI] = prepareData(config, nLayers, numberOfUE);

% =========================================================================
% Build representative UE pool
% =========================================================================
poolConfig.numClusters    = min(totalPMI, 50);
poolConfig.targetPoolSize = 200;
poolConfig.kmeansMaxIter  = 100;

disp('--- Running K-Means to build Representative Pool ---');
[W_pool, pool_indices, pool_pmi] = buildRepresentativePool( ...
    W_all, UE_Reported_Indices, poolConfig);

% =========================================================================
% Pre-compute distance matrix
% =========================================================================
NUE_pool = size(W_pool, 3);
fprintf('--- Pre-computing %dx%d distance matrix for W_pool ---\n', NUE_pool, NUE_pool);
distMat = zeros(NUE_pool, NUE_pool);
for i = 1:NUE_pool-1
    for j = i+1:NUE_pool
        d = chordalDistance(W_pool(:,:,i), W_pool(:,:,j));
        distMat(i,j) = d;
        distMat(j,i) = d;
    end
end
fprintf('--- Distance matrix ready ---\n');

% =========================================================================
% Configuration
% =========================================================================
groupSizes  = [2, 3, 4, 5];
maxIter     = 50;
threshold   = 0.90;

methodNames = {'Symbiotic Organisms Search (SOS)', 'Brute Force (BF)'};

% NaN = not run / skipped
allTimes  = NaN(2, length(groupSizes));
allScores = NaN(2, length(groupSizes));
allCounts = zeros(2, length(groupSizes));

bfFindAllOOM = false(1, length(groupSizes));

fprintf('\n========================================================\n');
fprintf('  GROUP SIZE SWEEP — FindAll Comparison\n');
fprintf('  Fixed threshold = %.2f\n', threshold);
fprintf('========================================================\n');

for gIdx = 1:length(groupSizes)
    K = groupSizes(gIdx);
    fprintf('\n--- Group Size K = %d ---\n', K);
    fprintf('  [FindAll] Fixed threshold = %.2f\n', threshold);

    % ── SOS FindAll ──────────────────────────────────────────────────────
    t = tic;
    [~, ~, sosValidGroups, sosValidScores] = sosMUMIMOSchedulingV2( ...
        W_pool, K, maxIter, threshold);
    allTimes(1, gIdx)  = toc(t);
    allCounts(1, gIdx) = length(sosValidScores);
    if ~isempty(sosValidScores)
        allScores(1, gIdx) = mean(sosValidScores);
    else
        allScores(1, gIdx) = 0;
    end

    % ── BF FindAll — K=5 skip (Out of Memory) ────────────────────────────
    if K < 5
        t = tic;
        [bfValidGroups, bfValidScores, numBFFound] = bruteForceFindAll( ...
            distMat, NUE_pool, K, threshold, Inf);
        allTimes(2, gIdx)  = toc(t);
        allCounts(2, gIdx) = numBFFound;
        if numBFFound > 0
            allScores(2, gIdx) = mean(bfValidScores);
        else
            allScores(2, gIdx) = 0;
        end
        bfFindAllOOM(gIdx) = false;
    else
        fprintf('  [BF FindAll] K=5: Skipped (Out of Memory)\n');
        allCounts(2, gIdx) = 0;
        bfFindAllOOM(gIdx) = true;
    end

    % ── Print summary ─────────────────────────────────────────────────────
    fprintf('\n  %-38s | Time: %7.3f s | MeanScore: %.4f | Found: %5d\n', ...
        methodNames{1}, allTimes(1,gIdx), allScores(1,gIdx), allCounts(1,gIdx));
    if ~bfFindAllOOM(gIdx)
        fprintf('  %-38s | Time: %7.3f s | MeanScore: %.4f | Found: %5d\n', ...
            methodNames{2}, allTimes(2,gIdx), allScores(2,gIdx), allCounts(2,gIdx));
    else
        fprintf('  %-38s | Time:     N/A   | MeanScore:    N/A | Found:   N/A  [Out of Memory]\n', ...
            methodNames{2});
    end
end

% =========================================================================
% FIGURES
% =========================================================================
cSOS = [0.17 0.63 0.17];   % xanh lá — SOS
cBF  = [1.00 0.50 0.05];   % cam     — BF

figPos = {[50  100 750 460], [50  600 750 460]};
xLbls  = {'K=2','K=3','K=4','K=5'};
k5idx  = find(groupSizes == 5);

% ── Figure 1: Execution Time ──────────────────────────────────────────────
figure('Name','Fig 1: Execution Time – FindAll','Color','w','Position',figPos{1});
ax = gca;

t_sos = allTimes(1,:);
t_bf  = allTimes(2,:);   % NaN at K=5

semilogy(groupSizes, t_sos, 's-','LineWidth',2,'MarkerSize',8, ...
    'Color',cSOS,'MarkerFaceColor',cSOS); hold on;

validBF = ~isnan(t_bf);
semilogy(groupSizes(validBF), t_bf(validBF), '^-','LineWidth',2,'MarkerSize',8, ...
    'Color',cBF,'MarkerFaceColor',cBF);

% Annotate OOM at K=5
semilogy(groupSizes(k5idx), t_sos(k5idx)*2, 'rx','MarkerSize',14,'LineWidth',2.5);
text(groupSizes(k5idx), t_sos(k5idx)*3.5, 'BF: Out of Memory', ...
    'FontSize',13,'FontName','Times New Roman','Color','r', ...
    'HorizontalAlignment','center','FontWeight','bold');

% Value labels
for gIdx = 1:length(groupSizes)
    if ~isnan(t_sos(gIdx))
        text(groupSizes(gIdx), t_sos(gIdx)*1.25, sprintf('%.2fs',t_sos(gIdx)), ...
            'FontSize',13,'FontName','Times New Roman', ...
            'HorizontalAlignment','center','Color',cSOS);
    end
    if ~isnan(t_bf(gIdx))
        text(groupSizes(gIdx), t_bf(gIdx)*0.6, sprintf('%.2fs',t_bf(gIdx)), ...
            'FontSize',13,'FontName','Times New Roman', ...
            'HorizontalAlignment','center','Color',cBF);
    end
end

grid on;
set(ax,'YMinorGrid','on','FontSize',18,'XColor','k','YColor','k', ...
    'GridColor',[0.5 0.5 0.5],'Color','w', ...
    'FontName','Times New Roman','LineWidth',1.2);
xticks(groupSizes); xticklabels(xLbls);
xlabel('Number of UEs per Group ($K$)','Interpreter','latex', ...
    'FontName','Times New Roman','FontSize',18,'Color','k');
ylabel('Execution Time (s) -- Log Scale','Interpreter','latex', ...
    'FontName','Times New Roman','FontSize',18,'Color','k');
title('Execution Time: FindAll --- SOS vs Brute Force', ...
    'FontSize',18,'FontWeight','bold','Color','k','FontName','Times New Roman');
lg = legend({'SOS FindAll','BF FindAll ($K$=2..4)'},'Location','northwest', ...
    'Interpreter','latex','FontSize',18);
set(lg,'TextColor','k','Color','w','EdgeColor',[0.5 0.5 0.5], ...
    'FontName','Times New Roman');

% ── Figure 2: Mean Score ──────────────────────────────────────────────────
figure('Name','Fig 2: Mean Score – FindAll','Color','w','Position',figPos{2});
ax = gca;

sc_sos = allScores(1,:);
sc_bf  = allScores(2,:);   % NaN at K=5

plot(groupSizes, sc_sos, 's-','LineWidth',2,'MarkerSize',8, ...
    'Color',cSOS,'MarkerFaceColor',cSOS); hold on;

validBF = ~isnan(sc_bf);
plot(groupSizes(validBF), sc_bf(validBF), '^-','LineWidth',2,'MarkerSize',8, ...
    'Color',cBF,'MarkerFaceColor',cBF);

% Annotate OOM at K=5
plot(groupSizes(k5idx), sc_sos(k5idx), 'rx','MarkerSize',14,'LineWidth',2.5);
text(groupSizes(k5idx), sc_sos(k5idx)-0.015, 'BF: Out of Memory', ...
    'FontSize',13,'FontName','Times New Roman','Color','r', ...
    'HorizontalAlignment','center','FontWeight','bold');

% Value labels
for gIdx = 1:length(groupSizes)
    if ~isnan(sc_sos(gIdx))
        text(groupSizes(gIdx), sc_sos(gIdx)+0.008, sprintf('%.4f',sc_sos(gIdx)), ...
            'FontSize',13,'FontName','Times New Roman', ...
            'HorizontalAlignment','center','Color',cSOS);
    end
    if ~isnan(sc_bf(gIdx))
        text(groupSizes(gIdx), sc_bf(gIdx)-0.010, sprintf('%.4f',sc_bf(gIdx)), ...
            'FontSize',13,'FontName','Times New Roman', ...
            'HorizontalAlignment','center','Color',cBF);
    end
end

grid on;
set(ax,'FontSize',18,'XColor','k','YColor','k','GridColor',[0.5 0.5 0.5],'Color','w', ...
    'FontName','Times New Roman','LineWidth',1.2);
xticks(groupSizes); xticklabels(xLbls);
allValid = [sc_sos(~isnan(sc_sos)), sc_bf(~isnan(sc_bf))];
if ~isempty(allValid)
    ylim([max(0, min(allValid)-0.05), min(1.05, max(allValid)+0.05)]);
end
xlabel('Number of UEs per Group ($K$)','Interpreter','latex', ...
    'FontName','Times New Roman','FontSize',18,'Color','k');
ylabel('Mean Score (Avg Chordal Distance)','Interpreter','latex', ...
    'FontName','Times New Roman','FontSize',18,'Color','k');
title('Mean Score: FindAll --- SOS vs Brute Force', ...
    'FontSize',18,'FontWeight','bold','Color','k','FontName','Times New Roman');
lg = legend({'SOS FindAll','BF FindAll ($K$=2..4)'},'Location','southwest', ...
    'Interpreter','latex','FontSize',18);
set(lg,'TextColor','k','Color','w','EdgeColor',[0.5 0.5 0.5], ...
    'FontName','Times New Roman');

fprintf('\n[DONE] All figures generated.\n');

% =========================================================================
% LOCAL HELPERS
% =========================================================================
function [validGroups, validScores, numFound] = bruteForceFindAll( ...
        distMat, NUE, groupSize, threshold, maxTimeLimit)

    if nargin < 5, maxTimeLimit = Inf; end

    numGroups        = floor(NUE / groupSize);
    numPairsPerGroup = groupSize*(groupSize-1)/2;

    fprintf('      [BF FindAll] Evaluating all C(%d,%d) combinations (K=%d)...\n', ...
        NUE, groupSize, groupSize);

    numCombos  = nchoosek(NUE, groupSize);
    combScores = zeros(numCombos, 1);
    combGroups = zeros(numCombos, groupSize);

    idx      = 0;
    group    = 1:groupSize;
    idxLimit = (NUE-groupSize+1):NUE;
    tStart   = tic;
    timedOut = false;

    while true
        if toc(tStart) > maxTimeLimit
            fprintf('      [BF FindAll] TIMEOUT after %.1fs (%d/%d combos).\n', ...
                toc(tStart), idx, numCombos);
            timedOut = true; break;
        end
        idx = idx + 1;
        d   = 0;
        for a = 1:groupSize-1
            for b = a+1:groupSize
                d = d + distMat(group(a), group(b));
            end
        end
        combScores(idx)    = d / numPairsPerGroup;
        combGroups(idx, :) = group;
        ptr = groupSize;
        while ptr>0 && group(ptr)==idxLimit(ptr), ptr=ptr-1; end
        if ptr==0, break; end
        group(ptr) = group(ptr)+1;
        for j = ptr+1:groupSize, group(j)=group(j-1)+1; end
    end

    combScores = combScores(1:idx);
    combGroups = combGroups(1:idx, :);

    [combScores, si] = sort(combScores, 'descend');
    combGroups       = combGroups(si, :);

    usedUE    = false(1, NUE);
    allGroups = cell(numGroups, 1);
    allScores = zeros(numGroups, 1);
    filled    = 0;

    for c = 1:size(combGroups, 1)
        grp = combGroups(c, :);
        if any(usedUE(grp)), continue; end
        filled            = filled + 1;
        allGroups{filled} = grp;
        allScores(filled) = combScores(c);
        usedUE(grp)       = true;
        if filled == numGroups, break; end
    end

    allGroups = allGroups(1:filled);
    allScores = allScores(1:filled);

    validMask   = allScores >= threshold;
    validGroups = allGroups(validMask);
    validScores = allScores(validMask);
    numFound    = length(validGroups);

    fprintf('      [BF FindAll] Done (%.1fs) | Pairs matched: %d | Above threshold: %d%s\n', ...
        toc(tStart), filled, numFound, ternary(timedOut, ' [TIMEOUT]', ''));
end

function out = ternary(cond, valTrue, valFalse)
    if cond, out = valTrue; else, out = valFalse; end
end

function [W_pool, pool_indices, pool_pmi] = buildRepresentativePool(W_all, UE_Reported_Indices, config)

    numClusters    = getField(config, 'numClusters',    50);
    targetPoolSize = getField(config, 'targetPoolSize', 200);
    kmeansMaxIter  = getField(config, 'kmeansMaxIter',  100);

    % L: Số layer (thường là số cột của W)
    [Nt, L, N] = size(W_all); 
    numClusters = min(numClusters, N);

    % =========================================================
    % BƯỚC 1: KHỞI TẠO TÂM CỤM (Chọn ngẫu nhiên từ data)
    % =========================================================
    % Khởi tạo tâm cụm A_c là các ma trận trực giao
    rng('default'); % Cố định random seed để kết quả lặp lại được (tùy chọn)
    init_idx = randperm(N, numClusters);
    Centroids = zeros(Nt, L, numClusters);
    for c = 1:numClusters
        Centroids(:,:,c) = orth(W_all(:,:,init_idx(c)));
    end

    labels = zeros(N, 1);

    % =========================================================
    % BƯỚC 2 & 3: VÒNG LẶP K-MEANS CHUẨN BEAMFORMING
    % =========================================================
    for iter = 1:kmeansMaxIter
        old_labels = labels;
        
        % 2. GÁN CỤM: Dựa trên khoảng cách Chordal
        % Công thức rút gọn của Chordal: d^2 = L - Trace(A^H * W * W^H * A)
        % Cách này chạy rất nhanh, không cần flatten ma trận
        for k = 1:N
            W_k = orth(W_all(:,:,k)); % Đảm bảo tính trực giao
            W_proj = W_k * W_k';      % W * W^H
            
            min_dist = inf;
            best_cluster = 1;
            for c = 1:numClusters
                A_c = Centroids(:,:,c);
                % Tính khoảng cách Chordal (càng nhỏ càng tốt)
                dist = L - real(trace(A_c' * W_proj * A_c)); 
                
                if dist < min_dist
                    min_dist = dist;
                    best_cluster = c;
                end
            end
            labels(k) = best_cluster;
        end
        
        % Kiểm tra điều kiện hội tụ (nếu các UE không đổi cụm nữa thì dừng)
        if isequal(labels, old_labels)
            break;
        end
        
        % 3. CẬP NHẬT TÂM CỤM: Dùng SVD trên ma trận tương quan tổng R_c
        for c = 1:numClusters
            members = find(labels == c);
            if isempty(members)
                % Nếu cụm rỗng, chọn đại một UE ngẫu nhiên làm tâm mới
                Centroids(:,:,c) = orth(W_all(:,:,randi(N)));
                continue;
            end
            
            % Tính ma trận tương quan tổng R_c
            R_c = zeros(Nt, Nt);
            for i = 1:length(members)
                idx = members(i);
                W_m = orth(W_all(:,:,idx));
                R_c = R_c + (W_m * W_m'); 
            end
            
            % Dùng SVD để tìm hướng năng lượng tập trung nhất
            [U, ~, ~] = svd(R_c);
            
            % Cập nhật tâm mới bằng cách lấy L vector riêng lớn nhất
            Centroids(:,:,c) = U(:, 1:L); 
        end
    end

    % =========================================================
    % BƯỚC 4: LẤY ĐẠI DIỆN GẦN CENTROID NHẤT CHO POOL
    % =========================================================
    ues_per_cluster = ceil(targetPoolSize / numClusters);
    pool_indices    = [];

    for c = 1:numClusters
        members = find(labels == c);
        if isempty(members), continue; end

        A_c = Centroids(:,:,c);
        
        % Tính lại khoảng cách Chordal từ các member đến tâm A_c cuối cùng
        d2 = zeros(length(members), 1);
        for i = 1:length(members)
            W_m = orth(W_all(:,:,members(i)));
            d2(i) = L - real(trace(A_c' * W_m * W_m' * A_c));
        end
        
        % Sắp xếp tăng dần (gần tâm nhất lên đầu)
        [~, ord] = sort(d2, 'ascend');

        num_to_pick  = min(ues_per_cluster, length(members));
        pool_indices = [pool_indices; members(ord(1:num_to_pick))];
    end

    W_pool   = W_all(:, :, pool_indices);
    pool_pmi = UE_Reported_Indices(pool_indices);
end

function v = getField(s, f, default)
    if isfield(s, f), v = s.(f); else, v = default; end
end

function [W_all, UE_Reported_Indices, totalPMI, PMI_list, H_list] = prepareData(config, nLayers, numberOfUE)
    SNR_dB = 20;
    % Extract codebook configuration parameters
    N1     = config.CodeBookConfig.N1;
    N2     = config.CodeBookConfig.N2;
    cbMode = config.CodeBookConfig.cbMode;
    nPort  = 2 * N1 * N2;
    filename = sprintf(config.FileName, nPort, nLayers, cbMode, N1, N2);

    fprintf('Loading precoding matrix pool from file: %s...\n', filename);

    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    W_pool      = [];
    pool_info   = {};
    pmi_in_file = 0;

    % Read all precoding matrices from file
    while ~feof(fid)
        info_line = fgetl(fid);
        if ~ischar(info_line), break; end
        if isempty(strtrim(info_line)), continue; end

        pmi_in_file = pmi_in_file + 1;
        pool_info{pmi_in_file} = info_line;

        W_temp = zeros(nPort, nLayers);
        for row = 1:nPort
            row_data = fgetl(fid);
            W_temp(row, :) = str2num(row_data);
        end
        W_pool(:, :, pmi_in_file) = W_temp;
    end
    fclose(fid);

    fprintf('Successfully loaded %d precoding matrices from file.\n', pmi_in_file);
    totalPMI = pmi_in_file;

    % -------------------------------------------------------------------------
    % Sinh numberOfUE kênh H ngẫu nhiên Rayleigh [Nr x nPort]
    % Với mỗi H tìm PMI tốt nhất: PMI = argmax_i ||H * W_i||^2_F
    % SNR không ảnh hưởng argmax với Type I nhưng truyền vào để mở rộng sau
    % -------------------------------------------------------------------------
    fprintf('Generating %d Rayleigh H [%d x %d], SNR = %d dB...\n', ...
        numberOfUE, nLayers, nPort, SNR_dB);

    H_list            = zeros(nLayers, nPort, numberOfUE);
    PMI_list          = zeros(numberOfUE, 1);       % 0-indexed
    best_idx_list     = zeros(numberOfUE, 1);       % 1-indexed (dùng nội bộ)

    for k = 1:numberOfUE
        % Sinh H theo Rayleigh fading
        H_k = (randn(nLayers, nPort) + 1j*randn(nLayers, nPort)) / sqrt(2);
        H_list(:, :, k) = H_k;

        % Tìm PMI tốt nhất
        best_val = -inf;
        best_idx = 1;
        for i = 1:totalPMI
            val = norm(H_k * W_pool(:, :, i), 'fro')^2;
            if val > best_val
                best_val = val;
                best_idx = i;
            end
        end

        PMI_list(k)      = best_idx - 1;   % 0-indexed
        best_idx_list(k) = best_idx;       % 1-indexed để index vào pool
    end

    fprintf('PMI search done. Extracting W and info...\n');

    % Vectorized extraction theo best_idx tìm được
    W_all               = W_pool(:, :, best_idx_list);
    UE_Reported_Indices = pool_info(best_idx_list);

    fprintf('Done. W_all: [%d x %d x %d]\n\n', size(W_all,1), size(W_all,2), size(W_all,3));
end

function orthogonalityScore = chordalDistance(PMI_m, PMI_n)
    if size(PMI_m, 1) ~= size(PMI_n, 1)
        error('Input matrices must have the same number of rows (Antennas).');
    end

    % Orthonormalize: đưa về orthonormal basis của subspace
    [Q_m, ~] = qr(PMI_m, 0);
    [Q_n, ~] = qr(PMI_n, 0);

    p = size(PMI_m, 2);
    r = size(PMI_n, 2);

    % Ye & Lim (2016): dùng L = max thay vì min
    L = max(p, r);

    % Cross-correlation giữa 2 subspace
    R  = Q_m' * Q_n;          % (p x r)

    % SVD để lấy principal angles
    sv = svd(R);
    sv = min(real(sv), 1.0);  % clamp floating-point

    % Pad zeros cho phần subspace không có cặp (góc = π/2, cos = 0)
    sv_padded = [sv; zeros(L - length(sv), 1)];

    % Grassmannian chordal distance, normalize về [0,1]
    chordalDist        = sqrt(max(L - sum(sv_padded.^2), 0));
    orthogonalityScore = chordalDist / sqrt(L);
end

function [bestGroups, bestScore, validGroups, validScores] = sosMUMIMOSchedulingV2(W_all, groupSize, maxIter, threshold)
    NUE       = size(W_all, 3);
    popSize   = 30;
    numGroups = floor(NUE / groupSize);

    population = zeros(popSize, NUE);
    for p = 1:popSize
        population(p, :) = randperm(NUE);
    end

    disp('      [SOS] Computing distance matrix...');
    distMat = zeros(NUE, NUE);
    for i = 1:NUE-1
        for j = i+1:NUE
            distMat(i,j) = chordalDistance(W_all(:,:,i), W_all(:,:,j));
            distMat(j,i) = distMat(i,j);
        end
    end

    fitnessFunc = @(perm) computeScheduleFitnessOptimize(perm, distMat, groupSize, numGroups);

    fitness = zeros(popSize, 1);
    for p = 1:popSize
        fitness(p) = fitnessFunc(population(p,:));
    end

    [bestScore, bestIdx] = max(fitness);
    bestPerm             = population(bestIdx, :);

    no_improve_counter = 0;
    max_no_improve     = 15;

    disp('      [SOS] Starting evolutionary generations...');
    for iter = 1:maxIter

        % MUTUALISM
        for i = 1:popSize
            j = randi(popSize);
            while j == i, j = randi(popSize); end
            newOrgI = mutualismSwap(population(i,:), population(j,:));
            newOrgJ = mutualismSwap(population(j,:), population(i,:));
            fI = fitnessFunc(newOrgI);
            if fI > fitness(i), population(i,:) = newOrgI; fitness(i) = fI; end
            fJ = fitnessFunc(newOrgJ);
            if fJ > fitness(j), population(j,:) = newOrgJ; fitness(j) = fJ; end
        end

        % COMMENSALISM
        for i = 1:popSize
            j = randi(popSize);
            while j == i, j = randi(popSize); end
            newOrg = commensalismSwap(population(i,:), population(j,:));
            fNew   = fitnessFunc(newOrg);
            if fNew > fitness(i), population(i,:) = newOrg; fitness(i) = fNew; end
        end

        % PARASITISM
        for i = 1:popSize
            parasite = parasitePerturb(population(i,:));
            host     = randi(popSize);
            while host == i, host = randi(popSize); end
            fParasite = fitnessFunc(parasite);
            if fParasite > fitness(host)
                population(host,:) = parasite;
                fitness(host)      = fParasite;
            end
        end

        [curBest, curIdx] = max(fitness);
        if curBest > bestScore
            bestScore          = curBest;
            bestPerm           = population(curIdx,:);
            no_improve_counter = 0;
        else
            no_improve_counter = no_improve_counter + 1;
        end

        if no_improve_counter >= max_no_improve
            fprintf('      [SOS] Converged at iter %d (score: %.4f)\n', iter, bestScore);
            break;
        end
    end

    % ── Cắt hoán vị → 100 cặp, tính score từng cặp, lọc threshold ───────
    bestGroups  = cell(numGroups, 1);
    pairScores  = zeros(numGroups, 1);
    numPairs    = groupSize*(groupSize-1)/2;

    for g = 1:numGroups
        idx  = (g-1)*groupSize + 1 : g*groupSize;
        grp  = bestPerm(idx);
        bestGroups{g} = grp;

        d = 0;
        for a = 1:groupSize-1
            for b = a+1:groupSize
                d = d + distMat(grp(a), grp(b));
            end
        end
        pairScores(g) = d / numPairs;
    end

    % Lọc các cặp >= threshold
    validMask   = pairScores >= threshold;
    validGroups = bestGroups(validMask);
    validScores = pairScores(validMask);

    % Sắp xếp theo score giảm dần
    [validScores, si] = sort(validScores, 'descend');
    validGroups       = validGroups(si);

    fprintf('      [SOS] Total pairs: %d | Above threshold (%.3f): %d\n', ...
        numGroups, threshold, sum(validMask));
end


% =========================================================================
% FITNESS FUNCTION
% =========================================================================
function score = computeScheduleFitnessOptimize(perm, distMat, groupSize, numGroups)
    totalDist        = 0;
    numPairsPerGroup = groupSize*(groupSize-1)/2;
    for g = 1:numGroups
        idx      = (g-1)*groupSize + 1 : g*groupSize;
        ueIdx    = perm(idx);
        groupDist = 0;
        for a = 1:groupSize-1
            for b = a+1:groupSize
                groupDist = groupDist + distMat(ueIdx(a), ueIdx(b));
            end
        end
        totalDist = totalDist + groupDist / numPairsPerGroup;
    end
    score = totalDist / numGroups;
end


% =========================================================================
% MUTATION / CROSSOVER OPERATORS
% =========================================================================
function newPerm = mutualismSwap(permA, permB)
    n   = length(permA);
    pt1 = randi(n); pt2 = randi(n);
    while pt1 == pt2, pt2 = randi(n); end
    if pt1 > pt2, [pt1,pt2] = deal(pt2,pt1); end

    segment     = permB(pt1:pt2);
    isInSegment = false(1,n);
    isInSegment(segment) = true;
    remaining   = permA(~isInSegment(permA));
    insertPos   = randi(length(remaining)+1);
    newPerm     = [remaining(1:insertPos-1), segment, remaining(insertPos:end)];
    assert(length(newPerm)==n, 'Error: newPerm length mismatch!');
end

function newPerm = commensalismSwap(permA, ~)
    newPerm      = permA;
    pts          = randperm(length(permA), 2);
    temp         = newPerm(pts(1));
    newPerm(pts(1)) = newPerm(pts(2));
    newPerm(pts(2)) = temp;
end

function parasite = parasitePerturb(perm)
    parasite  = perm;
    n         = length(perm);
    pts       = sort(randperm(n,2));
    parasite(pts(1):pts(2)) = parasite(pts(1) + randperm(pts(2)-pts(1)+1) - 1);
end