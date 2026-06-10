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