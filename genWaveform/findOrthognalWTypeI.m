% =========================================================================
% SCRIPT: K-MEANS + SOS VS GREEDY MU-MIMO SCHEDULING FOR 60,000 UEs
% Antenna: 32T32R | Compare execution time between SOS and Greedy sweep
% =========================================================================
clear; clc; close all; 
setupPath();

nLayers = 4;
numberOfUeToGroup = 2;

config.CodeBookConfig.N1 = 4;
config.CodeBookConfig.N2 = 4;
config.CodeBookConfig.cbMode = 1;
config.FileName = "Layer4_Port32_N1_4_N2-4_c1.txt";

% 3. Gọi hàm để đọc dữ liệu từ file
% Đảm bảo file .txt đang nằm cùng thư mục với script đang chạy
[W_all, UE_Reported_Indices] = prepareData(config, nLayers);

% =========================================================================
% 3. Pre-Processing: Build representative UE pool via K-Means clustering
% =========================================================================
poolConfig = struct();
poolConfig.numClusters    = 50;
poolConfig.targetPoolSize = 200;
poolConfig.kmeansMaxIter  = 100;

disp('--- Running K-Means to build Representative Pool ---');
[W_pool, pool_indices, pool_pmi] = buildRepresentativePool(W_all, UE_Reported_Indices, poolConfig);

% TÌM CẶP UE TRỰC GIAO NHẤT TRONG TOÀN BỘ POOL
% =========================================================================
fprintf('\n[Pre-search] Finding most orthogonal UE pair in pool...\n');
[best_ue_idx, best_W, bestScore, best_pmi] = findBestOrthogonalGroup(W_pool, pool_pmi, numberOfUeToGroup);

% =========================================================================
% LOCAL FUNCTIONS 
% =========================================================================
function [best_ue_idx, best_W, bestScore, best_pmi] = findBestOrthogonalGroup(W_pool, pool_pmi, num_users_to_group, maxIter)
    % Cài đặt maxIter mặc định nếu không truyền vào
    if nargin < 5
        maxIter = 50; 
    end

    % 1. Gọi thuật toán SOS để tìm lịch trình ghép nhóm cho toàn bộ UEs
    fprintf('[GroupSearch] Running SOS Algorithm for faster grouping...\n');
    [bestGroups, ~] = sosMUMIMOScheduling(W_pool, num_users_to_group, maxIter);

    % 2. Tìm nhóm xuất sắc nhất trong các nhóm mà SOS đã tạo ra 
    % (Sử dụng tiêu chí Max-Min giống hàm gốc của bạn)
    bestScore = -inf;
    best_ue_idx = [];

    numGroups = length(bestGroups);
    for g = 1:numGroups
        current_group = bestGroups{g};
        min_dist_in_group = inf;
        
        % Tính khoảng cách chordal nhỏ nhất trong nhóm này
        for i = 1:num_users_to_group-1
            for j = i+1:num_users_to_group
                u1 = current_group(i);
                u2 = current_group(j);
                dist = chordalDistance(W_pool(:,:,u1), W_pool(:,:,u2));
                if dist < min_dist_in_group
                    min_dist_in_group = dist;
                end
            end
        end
        
        % Cập nhật nếu nhóm này có min_dist tốt hơn
        if min_dist_in_group > bestScore
            bestScore = min_dist_in_group;
            best_ue_idx = current_group;
        end
    end

    % 3. Trích xuất đầu ra khớp với hàm cũ
    best_W = W_pool(:, :, best_ue_idx);
    best_pmi = pool_pmi(best_ue_idx);

    % =====================================================================
    % In kết quả
    % =====================================================================
    fprintf('\n========================================\n');
    fprintf('  Best orthogonal group found via SOS (Size = %d):\n', num_users_to_group);
    fprintf('  UEs: %s\n', num2str(best_ue_idx));
    fprintf('  Min Chordal Distance in group = %.6f\n', bestScore);
    fprintf('  (1 = hoàn toàn trực giao, 0 = hoàn toàn tương quan)\n');
    fprintf('========================================\n');
    for k = 1:num_users_to_group
        ue_id = best_ue_idx(k);
        fprintf('\nW%d (UE %d):\n', k, ue_id);
        disp(W_pool(:, :, ue_id));
        % plotBeamDirection(W_pool(:,:,ue_id), config.CodeBookConfig.N1, config.CodeBookConfig.N2);
    end

    for pmiIdx = 1:num_users_to_group 
        disp(best_pmi(pmiIdx));
    end
end

function [bestGroups, bestScore] = sosMUMIMOScheduling(W_all, groupSize, maxIter)
    % Get number of UE in the Cell
    NUE = size(W_all, 3);
    
    % Size of each group
    popSize = 30; 

    % The total number of groups
    numGroups = floor(NUE / groupSize);
    
    % Initialize the population: Each organism is a random permutation of UE indices
    population = zeros(popSize, NUE);
    for p = 1:popSize
        population(p, :) = randperm(NUE);
    end
    
    % Precompute the distance matrix (Symmetric Matrix) to minimize recalculation overhead
    disp('      [SOS] Computing distance matrix...');
    distMat = zeros(NUE, NUE);
    for i = 1:NUE-1
        for j = i+1:NUE
            distMat(i, j) = chordalDistance(W_all(:,:,i), W_all(:,:,j));
            distMat(j, i) = distMat(i, j); 
        end
    end
    
    % Initialize the function handle for fitness evaluation
    fitnessFunc = @(perm) computeScheduleFitnessOptimize(perm, distMat, groupSize, numGroups);
    
    fitness = zeros(popSize, 1);
    for p = 1:popSize
        fitness(p) = fitnessFunc(population(p, :));
    end
    
    % Identify the initial best organism
    [bestScore, bestIdx] = max(fitness);
    bestPerm = population(bestIdx, :);
    
    no_improve_counter = 0;
    % Early stopping condition: No improvement after 15 iterations
    max_no_improve = 15; 
    
    disp('      [SOS] Starting evolutionary generations...');
    for iter = 1:maxIter        
        % ===== MUTUALISM PHASE =====
        for i = 1:popSize
            j = randi(popSize);
            while j == i, j = randi(popSize); end
            
            % Crossover between organism i and j
            newOrgI = mutualismSwap(population(i,:), population(j,:));
            newOrgJ = mutualismSwap(population(j,:), population(i,:));
            
            % Update if the new organism has a higher score (better orthogonality)
            fI = fitnessFunc(newOrgI);
            if fI > fitness(i)
                population(i,:) = newOrgI;
                fitness(i) = fI;
            end
            
            fJ = fitnessFunc(newOrgJ);
            if fJ > fitness(j)
                population(j,:) = newOrgJ;
                fitness(j) = fJ;
            end
        end
        
        % ===== COMMENSALISM PHASE =====
        for i = 1:popSize
            j = randi(popSize);
            while j == i, j = randi(popSize); end
            
            % Random mutation on organism i
            newOrg = commensalismSwap(population(i,:), population(j,:));
            fNew = fitnessFunc(newOrg);
            if fNew > fitness(i)
                population(i,:) = newOrg;
                fitness(i) = fNew;
            end
        end
        
        % ===== PARASITISM PHASE =====
        for i = 1:popSize
            % Perturb the internal order of a segment to create a strong mutation
            parasite = parasitePerturb(population(i,:));
            host = randi(popSize);
            while host == i, host = randi(popSize); end
            
            % Parasite replaces the host if it has a higher fitness score
            fParasite = fitnessFunc(parasite);
            if fParasite > fitness(host)
                population(host,:) = parasite;
                fitness(host) = fParasite;
            end
        end
        
        % Check for convergence and update the global best
        [curBest, curIdx] = max(fitness);
        if curBest > bestScore
            bestScore = curBest;
            bestPerm = population(curIdx, :);
            no_improve_counter = 0; 
        else
            no_improve_counter = no_improve_counter + 1;
        end
        
        if no_improve_counter >= max_no_improve
            fprintf('      [SOS] Algorithm converged early at iteration %d (Score: %.4f)\n', iter, bestScore);
            break;
        end
    end
    
    % Extract the UE array into cell arrays based on group size
    bestGroups = cell(numGroups, 1);
    for g = 1:numGroups
        idx = (g-1)*groupSize + 1 : g*groupSize;
        bestGroups{g} = bestPerm(idx);
    end
end

% =========================================================================
% FITNESS FUNCTION 
% =========================================================================
function score = computeScheduleFitnessOptimize(perm, distMat, groupSize, numGroups)
    totalDist = 0;
    numPairsPerGroup = groupSize * (groupSize - 1) / 2; % Combinations of 2 within the group size
    
    for g = 1:numGroups
        idx = (g-1)*groupSize + 1 : g*groupSize;
        ueIdx = perm(idx);
        groupDist = 0;
        
        % Iterate through all UE pairs in a group and accumulate the orthogonal distance
        for a = 1:groupSize-1
            for b = a+1:groupSize
                groupDist = groupDist + distMat(ueIdx(a), ueIdx(b));
            end
        end
        
        totalDist = totalDist + groupDist / numPairsPerGroup;
    end
    % Return the average score across all scheduled groups
    score = totalDist / numGroups;
end

% =========================================================================
% MUTATION / CROSSOVER OPERATORS
% =========================================================================
function newPerm = mutualismSwap(permA, permB)
    n = length(permA);
    
    pt1 = randi(n);
    pt2 = randi(n);
    while pt1 == pt2
        pt2 = randi(n); % Đảm bảo 2 điểm không trùng nhau
    end
    
    if pt1 < pt2
        idx1 = pt1; idx2 = pt2;
    else
        idx1 = pt2; idx2 = pt1;
    end
    
    segment = permB(idx1:idx2); % Trích xuất một đoạn từ sinh vật B
    
    isInSegment = false(1, n); 
    isInSegment(segment) = true; % Đánh dấu 'true' cho những UE có trong segment
    
    remaining = permA(~isInSegment(permA));  
    
    maxInsert = length(remaining) + 1; 
    insertPos = randi(maxInsert);
    
    newPerm = [remaining(1:insertPos-1), segment, remaining(insertPos:end)];
    
    assert(length(newPerm) == n, 'Error: newPerm length mismatch after Swap!');
end

function newPerm = commensalismSwap(permA, ~)
    newPerm = permA;
    pts = randperm(length(permA), 2);
    
    % Swap the positions of any two elements (Point Mutation Operator)
    temp = newPerm(pts(1));
    newPerm(pts(1)) = newPerm(pts(2));
    newPerm(pts(2)) = temp;
end

function parasite = parasitePerturb(perm)
    parasite = perm;
    n = length(perm);
    pts = sort(randperm(n, 2));
    
    % Randomly scramble a sub-segment within the organism (Array Mutation Operator)
    parasite(pts(1):pts(2)) = parasite(pts(1) + randperm(pts(2)-pts(1)+1) - 1);
end

function [W_all, UE_Reported_Indices] = prepareData(config, nLayers)
    % Trích xuất thông số cấu hình
    N1 = config.CodeBookConfig.N1;
    N2 = config.CodeBookConfig.N2;
    cbMode = config.CodeBookConfig.cbMode; % Cần đảm bảo cbMode có trong config
    
    nPort = 2 * N1 * N2; % Số cổng anten
    
    % Tự động tạo tên file dựa trên cấu hình (ví dụ: Precoding_4Port4Layer_CBModeN1N2_121.txt)
    filename = sprintf(config.FileName, nPort, nLayers, cbMode, N1, N2);
    
    fprintf('Đang đọc ma trận precoder W_all từ file: %s...\n', filename);
    
    % Mở file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Không thể mở file: %s. Hãy đảm bảo file đang nằm cùng thư mục.', filename);
    end
    
    % Khởi tạo biến
    UE_Reported_Indices = {}; % Lưu thông tin info của từng ma trận
    W_all = [];               % Ma trận 3 chiều lưu toàn bộ các W
    pmi_count = 0;            % Đếm số lượng ma trận
    
    % Vòng lặp đọc toàn bộ file
    while ~feof(fid)
        info_line = fgetl(fid); % Đọc dòng thông tin PMI
        
        % Dừng nếu hết file
        if ~ischar(info_line)
            break;
        end
        
        % Bỏ qua các dòng trống (nếu có)
        if isempty(strtrim(info_line))
            continue;
        end
        
        pmi_count = pmi_count + 1;
        
        % Lưu dòng thông tin vào cell array thay vì struct random như cũ
        UE_Reported_Indices{pmi_count} = info_line; 
        
        % Khởi tạo ma trận tạm thời
        W_temp = zeros(nPort, nLayers);
        
        % Đọc các dòng chứa giá trị ma trận
        for row = 1:nPort
            row_data = fgetl(fid);
            W_temp(row, :) = str2num(row_data);
        end
        
        % Gán ma trận vừa đọc vào W_all
        W_all(:, :, pmi_count) = W_temp;
    end
    
    fclose(fid);
    
    % Hiển thị kích thước cuối cùng: [Số port x Số layer x Số PMI đọc được]
    fprintf('W_all completed: [%d x %d x %d]\n\n', size(W_all, 1), size(W_all, 2), size(W_all, 3));

end % end prepareData

function [W_pool, pool_indices, pool_pmi] = buildRepresentativePool(W_all, UE_Reported_Indices, config)
    % 1. Xử lý cấu hình an toàn (Thay thế getField để code độc lập hơn)
    if isfield(config, 'numClusters'), numClusters = config.numClusters; 
    else 
        numClusters = 50; 
    end
    if isfield(config, 'targetPoolSize'), targetPoolSize = config.targetPoolSize; 
    else 
        targetPoolSize = 200; 
    end
    if isfield(config, 'kmeansMaxIter'), kmeansMaxIter = config.kmeansMaxIter; 
    else 
        kmeansMaxIter = 100; 
    end

    % 2. Lấy kích thước thực tế của W_all
    [Num_Antennas, NumLayers, Num_UEs] = size(W_all);

    % 3. Đảm bảo số lượng cluster không được vượt quá số lượng ma trận thực tế
    % (Nếu file của bạn chỉ có 16 ma trận mà numClusters = 50 thì K-means sẽ báo lỗi)
    if numClusters > Num_UEs
        fprintf('Cảnh báo: numClusters (%d) lớn hơn số lượng ma trận (%d). Tự động gán lại numClusters = %d.\n', numClusters, Num_UEs, Num_UEs);
        numClusters = Num_UEs;
    end

    % 4. Chuẩn bị dữ liệu cho K-means
    % W_all [4 x 4 x Num_UEs] -> Trải phẳng thành W_flat [Num_UEs x 16]
    W_flat = reshape(W_all, Num_Antennas * NumLayers, Num_UEs).';
    
    % Tách phần thực và phần ảo để làm features (kích thước [Num_UEs x 32])
    W_features = [real(W_flat), imag(W_flat)];

    fprintf('Running K-means (%d clusters) on %d matrices...\n', numClusters, Num_UEs);
    
    % 5. Chạy K-means
    [cluster_idx, ~] = kmeans(W_features, numClusters, ...
                            'Distance', 'cosine',    ...
                            'MaxIter',  kmeansMaxIter);

    % 6. Rút trích tập đại diện (Pool)
    ues_per_cluster = ceil(targetPoolSize / numClusters);
    pool_indices = [];
    
    for c = 1:numClusters
        members     = find(cluster_idx == c);
        members     = members(randperm(length(members))); % Xáo trộn ngẫu nhiên thứ tự
        num_to_pick = min(ues_per_cluster, length(members));
        pool_indices = [pool_indices; members(1:num_to_pick)];
    end

    % 7. Gán kết quả đầu ra
    W_pool   = W_all(:, :, pool_indices);
    pool_pmi = UE_Reported_Indices(pool_indices);   % <-- cell array PMI theo pool

    fprintf('Representative pool: %d matrices from %d clusters (target: %d).\n\n', ...
            length(pool_indices), numClusters, targetPoolSize);
end