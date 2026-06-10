function pdsch = linkAdaption(pdschConfig, MCS, SystemSNR)
% LINKADAPTION Performs simple Link Adaptation (AMC) based on SNR thresholds.
%
%   Inputs:
%       pdschConfig : Custom object or struct representing PDSCH configuration.
%                     Must support method: .setMCS(val) and property: .Modulation.
%       MCS         : Initial (maximum) MCS index to start checking from.
%       SystemSNR   : The measured System SNR (in dB).
%
%   Output:
%       pdsch       : The updated pdschConfig with the highest feasible MCS.

    current_MCS = MCS;

    % Iterate downwards from the initial MCS
    while current_MCS >= 0
        % Update the PDSCH configuration with the current MCS index.
        % Note: This assumes 'pdschConfig' has a method 'setMCS' that updates 
        % its internal modulation and coding rate properties.
        pdschConfig = pdschConfig.setMCS(current_MCS);
        
        % Determine the required SNR threshold based on the resulting Modulation.
        % These thresholds are hardcoded examples; in a real system, 
        % these would come from BLER curves or lookup tables.
        switch pdschConfig.Modulation
            case 'QPSK'
                expected_SNR = 10;   % Minimum dB for QPSK
            case '16QAM'
                expected_SNR = 20;   % Minimum dB for 16QAM
            case '64QAM'
                expected_SNR = 30;   % Minimum dB for 64QAM
            case '256QAM'
                expected_SNR = 40;   % Minimum dB for 256QAM
            otherwise
                expected_SNR = 100;  % Unknown modulation, force skip
        end
        
        % Check if the System SNR is sufficient for this modulation
        if expected_SNR <= SystemSNR
            % If the system SNR supports this MCS/Modulation, stop here.
            % We have found the highest possible MCS that fits the channel.
            break;
        else
            % If SNR is too low, decrease MCS and try the next lower configuration.
            current_MCS = current_MCS - 1;
        end
    end

    % Return the final configured object
    pdsch = pdschConfig;
end