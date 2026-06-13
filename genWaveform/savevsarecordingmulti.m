function savevsarecordingmulti(fileName, data, sampleFreq, centerFreq, nChannel)
halfSpan = sampleFreq/1.28/2;
InputCenter = 0;
if nargin >3
    InputCenter = centerFreq;
end
InputZoom = uint8(1);
XDelta = 1 / sampleFreq;
XDomain = int16(2);
XStart = 0;
XUnit = 'Sec';
YUnit = 'V';
if nChannel ==1
    FreqValidMax = halfSpan + InputCenter;
    FreqValidMin = -halfSpan + InputCenter;
    InputRange = 1;
    InputRefImped = 50;
    Y = single(data);
    save(fileName, 'FreqValidMax','FreqValidMin','InputCenter','InputRange','InputRefImped','InputZoom','XDelta','XDomain','XUnit','XStart','YUnit','Y');
elseif nChannel ==2
    FreqValidMax1 = halfSpan + InputCenter;
    FreqValidMax2 = FreqValidMax1;
    FreqValidMin1 = - halfSpan + InputCenter;
    FreqValidMin2 = FreqValidMin1;
    InputRange1 = 1;
    InputRange2 = InputRange1;
    InputRefImped1 = 50;
    InputRefImped2 = InputRefImped1;
    Y1 = single(data(:,1));
    Y2 = single(data(:,2));
    save(fileName, 'FreqValidMax1','FreqValidMax2','FreqValidMin1','FreqValidMin2','InputCenter',...
        'InputRange1','InputRange2','InputRefImped1','InputRefImped2','InputZoom','XDelta','XDomain','XUnit','XStart','YUnit','Y1','Y2');
else
    save(fileName, 'InputCenter','InputZoom','XDelta','XDomain','XUnit','XStart','YUnit');
    for indx= 1:nChannel
        eval(['FreqValidMax' num2str(indx) '= halfSpan + InputCenter;']);
        eval(['FreqValidMin' num2str(indx) '= -halfSpan + InputCenter;']);
        eval(['InputRange' num2str(indx) '= 1;']);
        eval(['InputRefImped' num2str(indx) '= 50;']);
        eval(['Y' num2str(indx) '_' num2str(nChannel) '= single(data(:,' num2str(indx) '));']);

        save(fileName, ['FreqValidMax' num2str(indx)], ['FreqValidMin' num2str(indx)],...
            ['InputRange' num2str(indx)], ['InputRefImped' num2str(indx)],...
            ['Y' num2str(indx) '_' num2str(nChannel)], '-append');
    end
end