function outputBits = concentration(codeblocks)
    if iscell(codeblocks)
        outputBits = vertcat(codeblocks{:});
    else
        outputBits = codeblocks(:); 
    end
end