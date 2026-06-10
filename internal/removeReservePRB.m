function out = removeReservePRB(carrier, pdschAlPRB, pdschAlSym, ReservedPRB)
% -----------------------------------------------------------
% REMOVERESERVEPRB: Filters Reserved Resources from Allocation
% -----------------------------------------------------------
% Removes PRBs that overlap with configured Reserved Resources (e.g.,
% CORESETs, other signal reservations) from the PDSCH allocation.
%
% Inputs:
%   carrier     : Struct {NSlot, SymbolsPerSlot}
%   pdschAlPRB  : Vector of PRB indices OR Cell Array of PRBs per symbol.
%   pdschAlSym  : Vector of symbols allocated to PDSCH (0-based).
%   ReservedPRB : Cell Array of structs. Each struct defines:
%                 - PRBSet    : Vector of reserved PRBs.
%                 - SymbolSet : Symbols within the period (0-based).
%                 - Period    : [Periodicity (slots), Offset].
%
% Output:
%   out : Cell Array (1 x SymbolsPerSlot). 
%         Each cell contains the list of valid PRBs for that symbol.
% -----------------------------------------------------------

    nSlot = carrier.NSlot;
    SymbolsPerSlot = carrier.SymbolsPerSlot;

    % -----------------------------------------------------------
    % INITIALIZE OUTPUT STRUCTURE
    % -----------------------------------------------------------
    % Normalize the PRB allocation into a per-symbol Cell Array.
    % If pdschAlPRB is a vector, it implies the same PRBs are used 
    % for all allocated symbols.
    % -----------------------------------------------------------
    if iscell(pdschAlPRB)
        out = pdschAlPRB;
    else
        % Create a cell for every symbol in the slot (0 to 13)
        % containing the full PRB set initially.
        out = repmat({pdschAlPRB}, 1, SymbolsPerSlot);
    end

    % -----------------------------------------------------------
    % ITERATE RESERVED RESOURCE CONFIGURATIONS
    % -----------------------------------------------------------
    for idx = 1:length(ReservedPRB)
        PRBSet_Res = ReservedPRB{idx}.PRBSet;
        SymbolSet_Res = ReservedPRB{idx}.SymbolSet;
        Period_Res = ReservedPRB{idx}.Period;

        % -----------------------------------------------------------
        % DETERMINE AFFECTED SYMBOLS IN CURRENT SLOT
        % -----------------------------------------------------------
        if isempty(Period_Res)
            % Non-periodic (Static) Reservation:
            % The SymbolSet applies directly to every slot.
            AllSymbolSet = SymbolSet_Res; 
        else
            % Periodic Reservation:
            % Checks if the reservation pattern falls within the current slot.
            
            % Get Periodicity (in Slots)
            periodVal = double(Period_Res(1)); 
            
            % -----------------------------------------------------------
            % Calculate Offset for Current Slot
            % Logic assumes 'SymbolSet_Res' is defined relative to the start
            % of the period cycle (spanning multiple slots).
            % -----------------------------------------------------------
            
            % Calculate how many symbols have passed in the current period cycle
            % up to the start of the current slot.
            offset = mod(double(nSlot), periodVal) * SymbolsPerSlot;
             
            % Shift the Reserved Symbol Set back by the offset.
            tempSymbols = SymbolSet_Res - offset;
             
            % Filter symbols: Keep only those that fall within the current slot boundary
            % i.e., indices 0 to (SymbolsPerSlot - 1).
            AllSymbolSet = tempSymbols(tempSymbols >= 0 & tempSymbols < SymbolsPerSlot);
        end

        % -----------------------------------------------------------
        % PROCESS AFFECTED SYMBOLS
        % -----------------------------------------------------------
        for symIdx = 1:length(AllSymbolSet)
            currentResSym = AllSymbolSet(symIdx); % 0-based Symbol Index

            % -----------------------------------------------------------
            % Check Overlap
            % Only proceed if PDSCH is actually allocated on this symbol.
            % -----------------------------------------------------------
            if ismember(currentResSym, pdschAlSym)
                cellIndex = currentResSym + 1; % MATLAB Cell Index (1-based)

                currentPRBs = out{cellIndex}; % Get currently allocated PRBs

                % -----------------------------------------------------------
                % Remove Reserved PRBs
                % 'setdiff' returns data in 'currentPRBs' that is NOT in 'PRBSet_Res'.
                % 'stable' flag preserves the original sorting/order of PRBs.
                % -----------------------------------------------------------
                newPRBs = setdiff(currentPRBs, PRBSet_Res, 'stable');

                % Update the allocation for this symbol
                out{cellIndex} = newPRBs;
            end
        end
    end
end