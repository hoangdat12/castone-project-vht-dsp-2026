function bgn = baseGraphSelection(inBits, bitRates)
    A = length(inBits);

    if A <= 292 || (A <= 3824 && bitRates <= 0.67) || bitRates < 0.25
        bgn = 2;
    else
        bgn = 1;
    end
end