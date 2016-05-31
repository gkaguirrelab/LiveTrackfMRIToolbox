%% Load the data
clearvars
for i = 1:9
    
    load(['/Users/mspits/Dropbox (Aguirre-Brainard Lab)/MELA_data/MelanopsinMR_Pupil/HERO_aso1/053116/MatFiles/HERO_aso1-MelanopsinMR_Pupil-0' num2str(i) '.mat']);
    
    % Define some parameters
    dt = 1/30;
    nSeconds = 448; nTRDurSec = 0.8;
    nTTLPulses = nSeconds/nTRDurSec;
    
    % See if we have any dropped frames
    rData.frameCount = [params.Report.frameCount];
    %if ~(rData.frameCount == rData.frameCount(1):rData.frameCount(end))
    %   error('Dropped frames detected')
    %end
    
    % Extract the triggers and find the first TTL pulse
    rData.TTLPulses = [params.Report.Digital_IO1];
    [~, rData.TTLPulsesIdx] = find(rData.TTLPulses); rData.TTLPulsesIdx = sort(rData.TTLPulsesIdx);
    rData.TTLStart = rData.TTLPulsesIdx(1);
    rData.TTLEnd = rData.TTLPulsesIdx(end)+(nTRDurSec/dt)+50; % Leave a buffer to account for timing uncertainties in the TTL pulses
    sum(rData.TTLPulses)
    rData.TTLEnd-rData.TTLStart
    
    rData.pupilWidth = [params.Report.LeftPupilWidth];
    pData.t = 0:dt:(nTTLPulses*nTRDurSec); nSamples = length(pData.t);
    pData.pupilWidth = rData.pupilWidth(rData.TTLStart:(rData.TTLStart+nSamples));
    pData.pupilWidthMeanCentered = (pData.pupilWidth-mean(pData.pupilWidth)) ./ mean(pData.pupilWidth);
    pData.TTLPulses = rData.TTLPulses(rData.TTLStart:(rData.TTLStart+nSamples));
    
    % Replace 0 with NaN
    blankIdx = find(rData.pupilWidth == 0);
    blankIdx = [blankIdx blankIdx+1  blankIdx-1  blankIdx+2  blankIdx-2  blankIdx+3  blankIdx-3 blankIdx+4  blankIdx-4];
    blankIdx(blankIdx < 1) = [];
    rData.pupilWidth(blankIdx) = NaN;
    plot(i*1000+rData.pupilWidth, '-k'); hold on;
end
pbaspect([1 0.5 1]);
xlabel('Sample #');

%%
% Extract 16 second segments
% Load in the data
load('/Users/mspits/Dropbox (Aguirre-Brainard Lab)/MELA_data/MelanopsinMRMaxMelCRF/HERO_asb1/052716/MatFiles/HERO_asb1-MelanopsinMRMaxMelCRF-07.mat')
phaseShifts = params.thePhaseOffsetSec(params.thePhaseIndices);
maxContrastIdx = find(params.theContrastRelMaxIndices == 5);
%%
nSegments = 28; segmentDurSecs = 16;
s = 1;
nSamplesPerSegment = segmentDurSecs/dt;
timeVector = [];
dataVector = [];
for i = 1:nSamplesPerSegment:(nSegments*segmentDurSecs/dt)
    if ismember(s, maxContrastIdx)
        
        phaseShifts(s)
        startIdx = i; endIdx = i+479;
        t = pData.t(startIdx:endIdx);
        %plot(t-t(1), pData.pupilWidthMeanCentered(startIdx:endIdx)); hold on;
        timeVector = [timeVector (t-t(1)-phaseShifts(s))'];
        dataVector = [dataVector pData.pupilWidthMeanCentered(startIdx:endIdx)'];
        % Increment the segment counter
    end
    s = s+1;
end

% Plot the averages
for ii = 1:5
    plot(timeVector(:, ii), dataVector(:, ii)); hold on;
end
xlim([0 14]);
xlabel('Time [sec]');
ylabel('Pupil diameter [% change]'); ylim([-0.6 0.6]);