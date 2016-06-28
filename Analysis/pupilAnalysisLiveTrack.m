%% Identify the user
if isunix
    [~, user_name] = system('whoami') ; % exists on every unix that I know of
    % on my mac, isunix == 1
elseif ispc
    [~, user_name] = system('echo %USERDOMAIN%\%USERNAME%') ; % Not as familiar with windows,
    % found it on the net elsewhere, you might want to verify
end

% Path to local Dropbox
localDropboxDir = ['/Users/',strtrim(user_name),'/Dropbox (Aguirre-Brainard Lab/'] ;

%% HERO_asb1
clearvars;
subjectID = 'HERO_asb1';
dateID = '060816';
protocol = 'MelanopsinMRMaxLMSCRF';
acquisitionFreq = 60;
NRuns = 9;

%%
clearvars;
subjectID = 'HERO_asb1';
dateID = '060716';
protocol = 'MelanopsinMRMaxMelCRF';
acquisitionFreq = 60;
NRuns = 9;

%% HERO_aso1
clearvars;
subjectID = 'HERO_aso1';
dateID = '060116';
protocol = 'MelanopsinMRMaxLMSCRF';
acquisitionFreq = 30;
NRuns = 9;

%%
clearvars;
subjectID = 'HERO_aso1';
dateID = '053116';
protocol = 'MelanopsinMRMaxMelCRF';
acquisitionFreq = 30;
NRuns = 9;

%% HERO_gka1
clearvars;
subjectID = 'HERO_gka1';
dateID = '060616';
protocol = 'MelanopsinMRMaxLMSCRF';
acquisitionFreq = 60;
NRuns = 9;

%%
clearvars;
subjectID = 'HERO_gka1';
dateID = '060216';
protocol = 'MelanopsinMRMaxMelCRF';
acquisitionFreq = 30;
NRuns = 9;

%% HERO_mxs1
clearvars;
subjectID = 'HERO_mxs1';
dateID = '062816';
protocol = 'MelanopsinMRMaxLMSCRF';
acquisitionFreq = 60;
NRuns = 9;

%%
clearvars;
subjectID = 'HERO_mxs1';
dateID = '061016';
protocol = 'MelanopsinMRMaxMelCRF';
acquisitionFreq = 60;
NRuns = 4;

%% Set some parameters
params.TRDurSecs = 0.8; % secs
params.NTRsExpected = 560; % #
params.LiveTrackSamplingRate = 60; % Hz
params.ResamplingFineFreq = 1000; % 1 msec
params.TimeVectorFine = 0:(1/params.ResamplingFineFreq):((params.NTRsExpected*params.TRDurSecs)-(1/params.ResamplingFineFreq));
params.BlinkWindowSample = -10:10; % Samples surrounding the blink event

% Print out what we are analyzing
fprintf('\n');
fprintf('= Analyzing <strong>%s</strong> - <strong>%s</strong> - <strong>%s</strong>\n', protocol, subjectID, dateID);

exptPath = fullfile(localDropbopxDir, 'MELA_data', protocol, subjectID, dateID);
outPath = fullfile(localDropbopxDir, 'MELA_analysis', protocol, subjectID);
if ~isdir(outPath)
    mkdir(outPath);
end

for rrun = 1:NRuns
    %
    %%% EYE TRACKING DATA %%%
    % Load the eye tracking data
    Data_LiveTrack = load(fullfile(exptPath, 'EyeTrackingFiles', [subjectID '-' protocol '-' num2str(rrun, '%02.f') '.mat']));
    
    % Find cases in which the TTL pulse signal was split over the two
    % samples, and remove the second sample.
    Data_LiveTrack_TTLPulses_raw = [Data_LiveTrack.params.Report.Digital_IO1];
    tmpIdx = strfind(Data_LiveTrack_TTLPulses_raw, [1 1]);
    Data_LiveTrack_TTLPulses_raw(tmpIdx) = 0;
    
    % We reconstruct the data set collected at 30/60 Hz.
    Data_LiveTrack_TTLPulses = [];
    Data_LiveTrack_PupilDiameter = [];
    Data_LiveTrack_IsTracked = [];
    for rr = 1:length(Data_LiveTrack.params.Report)
        % Depending on how we set up the acquisiton frequency, we have to
        % do different things to extract the data
        switch acquisitionFreq
            case 60
                Data_LiveTrack_TTLPulses = [Data_LiveTrack_TTLPulses Data_LiveTrack_TTLPulses_raw(rr) 0];
                
                % We use the pupil width as the index of pupil diameter
                Data_LiveTrack_PupilDiameter = [Data_LiveTrack_PupilDiameter Data_LiveTrack.params.Report(rr).PupilWidth_Ch01 ...
                    Data_LiveTrack.params.Report(rr).PupilWidth_Ch02];
                
                % Special case
                if strcmp(dateID, '060616') && strcmp(subjectID, 'HERO_gka1');
                    Data_LiveTrack_IsTracked = [Data_LiveTrack_IsTracked Data_LiveTrack.params.Report(rr).PupilTracked ...
                        Data_LiveTrack.params.Report(rr).S2Tracked];
                else
                    Data_LiveTrack_IsTracked = [Data_LiveTrack_IsTracked Data_LiveTrack.params.Report(rr).PupilTracked_Ch01 ...
                        Data_LiveTrack.params.Report(rr).PupilTracked_Ch02];
                end
            case 30
                Data_LiveTrack_TTLPulses = [Data_LiveTrack_TTLPulses Data_LiveTrack_TTLPulses_raw(rr)];
                Data_LiveTrack_PupilDiameter = [Data_LiveTrack_PupilDiameter Data_LiveTrack.params.Report(rr).LeftPupilWidth];
                Data_LiveTrack_IsTracked = [Data_LiveTrack_IsTracked Data_LiveTrack.params.Report(rr).PupilTracked];
                
        end
    end
    
    % Now, we reconstruct the time vector of the data.
    TTLPulseIndices = find(Data_LiveTrack_TTLPulses); FirstTTLPulse = TTLPulseIndices(1);
    TimeVectorLinear = zeros(1, size(Data_LiveTrack_TTLPulses, 2));
    TimeVectorLinear(TTLPulseIndices) = (1:params.NTRsExpected)-1;
    
    % Replace zeros with NaN
    tmpX = 1:length(TimeVectorLinear);
    TimeVectorLinear(TimeVectorLinear == 0) = NaN;
    TimeVectorLinear(isnan(TimeVectorLinear)) = interp1(tmpX(~isnan(TimeVectorLinear)), ...
        TimeVectorLinear(~isnan(TimeVectorLinear)), tmpX(isnan(TimeVectorLinear)), 'linear', 'extrap');
    
    % Resample the timing to 1 msecs sampling
    Data_LiveTrack_PupilDiameter_FineMasterTime = interp1(TimeVectorLinear*params.TRDurSecs, ...
        Data_LiveTrack_PupilDiameter, params.TimeVectorFine);
    Data_LiveTrack_IsTracked_FineMasterTime = interp1(TimeVectorLinear*params.TRDurSecs, ...
        Data_LiveTrack_IsTracked, params.TimeVectorFine, 'nearest'); % Use NN interpolation for the binary tracking state
    
    %
    %%% Stimulus data %%%
    % Load the stimulus data
    Data_Stimulus = load(fullfile(exptPath, 'MatFiles', ...
        [subjectID '-' protocol '-' num2str(rrun, '%02.f') '.mat']));
    
    % Extract the stimulus timing
    keyPressWhich = [];
    keyPressWhen = [];
    for rr = 1:length(Data_Stimulus.params.responseStruct.events)
        keyPressWhich = [keyPressWhich Data_Stimulus.params.responseStruct.events(rr).buffer.keyCode];
        keyPressWhen = [keyPressWhen Data_Stimulus.params.responseStruct.events(rr).buffer.when];
    end
    
    % Extract only the ts
    keyPressWhen = keyPressWhen(keyPressWhich == 18);
    
    % Tack the first t also in this vector
    Data_Stimulus_TTL = [Data_Stimulus.params.responseStruct.tBlockStart keyPressWhen];
    
    % Subtract the absolute time of the first t
    Data_Stimulus_TTL_t0 = Data_Stimulus_TTL(1);
    Data_Stimulus_TTL = Data_Stimulus_TTL-Data_Stimulus_TTL_t0;
    
    % Check that we have as many TRs as we expect
    fprintf('> Expecting <strong>%g</strong> TRs - Found <strong>%g</strong> (LiveTrack) and <strong>%g</strong> (OneLight record).\n', ...
        params.NTRsExpected, sum(Data_LiveTrack_TTLPulses), length(Data_Stimulus_TTL));
    if (params.NTRsExpected == sum(Data_LiveTrack_TTLPulses)) || (params.NTRsExpected == length(Data_Stimulus_TTL))
        fprintf('\t>> Expected number of TRs matches actual number.\n');
    else
        error('\t>> Mismatch between expected and actual number of TRs received.');
    end
    
    % Extract the start times of the segments and subtract the time of the
    % first t
    Data_Stimulus_SegmentStartTimes = [Data_Stimulus.params.responseStruct.events.tTrialStart]-Data_Stimulus_TTL_t0;
    
    % Construct the fine timing vector. We do this by finding the 1 msec
    % bin corresponding to the time stamp, and assigning it the index of
    % the TR
    Data_Stimulus_SegmentIndex_Fine = NaN*params.TimeVectorFine;
    for rr = 1:length(Data_Stimulus_SegmentStartTimes)
        [~, idx] = min(abs(params.TimeVectorFine-Data_Stimulus_SegmentStartTimes(rr)));
        Data_Stimulus_SegmentIndex_Fine(idx) = rr;
    end
    Data_Stimulus_TTL_Fine =  NaN*params.TimeVectorFine;
    for rr = 1:length(Data_Stimulus_TTL)
        [~, idx] = min(abs(params.TimeVectorFine-Data_Stimulus_TTL(rr)));
        Data_Stimulus_TTL_Fine(idx) = params.TRDurSecs*(rr-1); % Subtract 1 so that we start at 0
    end
    
    % As before, we interpolate in 'linear TR time'
    tmpX = 1:length(Data_Stimulus_TTL_Fine);
    Data_Stimulus_TTL_Fine(isnan(Data_Stimulus_TTL_Fine)) = interp1(tmpX(~isnan(Data_Stimulus_TTL_Fine)), ...
        Data_Stimulus_TTL_Fine(~isnan(Data_Stimulus_TTL_Fine)), tmpX(isnan(Data_Stimulus_TTL_Fine)), 'linear', 'extrap');
    
    % We now move the stimulus onset information that we have in the finely
    % sampled native stimulus time to the finely sampled master time
    % vector. We do that by finding the indices in the master time vector
    % which correspond to the indices in the native stimulus time vector.
    Data_Stimulus_Segment_FineMasterTime = NaN*params.TimeVectorFine;
    tmpIdx = find(~isnan(Data_Stimulus_SegmentIndex_Fine));
    for rr = 1:length(tmpIdx)
        [~, idx] = min(abs(Data_Stimulus_TTL_Fine(tmpIdx(rr)) - params.TimeVectorFine));
        Data_Stimulus_Segment_FineMasterTime(idx) = rr;
    end
    
    % We now have four variables of interest
    %   Data_Stimulus_Segment_FineMasterTime <- contains the segment index starting at a given time sample
    %   Data_LiveTrack_IsTracked_FineMasterTime <- Binary array indicating tracking state
    %   Data_LiveTrack_PupilDiameter_FineMasterTime <- Pupil diameter
    %   params.TimeVectorFine <- Time vector in TR time
    
    % Remove blinks from the pupil data
    Data_LiveTrack_BlinkIdx = [];
    for rr = 1:length(params.BlinkWindowSample)
        Data_LiveTrack_BlinkIdx = [Data_LiveTrack_BlinkIdx find(~Data_LiveTrack_IsTracked_FineMasterTime)+params.BlinkWindowSample(rr)];
    end
    % Remove any blinks from before the first sample
    Data_LiveTrack_BlinkIdx(Data_LiveTrack_BlinkIdx < 1) = []; %% ALSO CUT THE BLINKING OFF AT THE END
    
    % Remove any blinks after the last sample
    Data_LiveTrack_BlinkIdx(Data_LiveTrack_BlinkIdx > length(Data_LiveTrack_IsTracked_FineMasterTime)) = []; %% ALSO CUT THE BLINKING OFF AT THE END
    Data_LiveTrack_BlinkIdx = unique(Data_LiveTrack_BlinkIdx);
    Data_LiveTrack_PupilDiameter_FineMasterTime(Data_LiveTrack_BlinkIdx) = NaN;
    
    % Interpolate the elements
    Data_LiveTrack_PupilDiameter_FineMasterTime(isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)) = interp1(params.TimeVectorFine(~isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)), Data_LiveTrack_PupilDiameter_FineMasterTime(~isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)), params.TimeVectorFine(isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)));
    Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered = (Data_LiveTrack_PupilDiameter_FineMasterTime-nanmean(Data_LiveTrack_PupilDiameter_FineMasterTime))./(nanmean(Data_LiveTrack_PupilDiameter_FineMasterTime));
    
    % Low-pass filter the pupil data
    % Set up filter properties
    NFreqsToFilter = 8; % Number of low frequencies to remove
    for ii = 1:NFreqsToFilter
        X(2*ii-1,:)=sin(linspace(0,2*pi*ii,448000));
        X(2*ii,:)=cos(linspace(0,2*pi*ii,448000));
    end
    
    % Filter it
    [b, bint, r]=regress(Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered',X');
    subplot(3,1,1)
    plot(params.TimeVectorFine, Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered)
    subplot(3,1,2)
    plot(params.TimeVectorFine, r)
    subplot(3,1,3)
    plot(params.TimeVectorFine, Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered-r')
    
    % Create the filtered version
    Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered_f = r';
    
    % Find the indices of the segment starting times
    NSeconds = 13;
    startIdx = find(~isnan(Data_Stimulus_Segment_FineMasterTime));
    
    % Adjust the phase
    thePhases = Data_Stimulus.params.thePhaseOffsetSec(Data_Stimulus.params.thePhaseIndices);
    for ii = 1:length(startIdx)
        startIdx(ii) = startIdx(ii) + thePhases(ii)*params.ResamplingFineFreq;
    end
    
    NSegments = length(startIdx);
    durIdx = NSeconds*params.ResamplingFineFreq-1;
    for ii = 1:NSegments
        if startIdx(ii)+durIdx > length(Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered_f)
            Data_Per_Segment{ii} = Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered_f(startIdx(ii):end)';
        else
            Data_Per_Segment{ii} = Data_LiveTrack_PupilDiameter_FineMasterTime_MeanCentered_f(startIdx(ii):(startIdx(ii)+durIdx))';
        end
    end
    
    % Separate out per contrast level
    Data_Stimulus.params.theContrastRelMaxIndices(find(Data_Stimulus.params.theDirections == 2)) = NaN;
    theContrastsScaled = Data_Stimulus.params.theContrastsPct*Data_Stimulus.params.theContrastMax;
    NContrastLevels = max(Data_Stimulus.params.theContrastRelMaxIndices);
    for ii = 1:NContrastLevels
        theIdx = find(Data_Stimulus.params.theContrastRelMaxIndices == ii);
        Data_Per_ContrastLevel{ii, rrun} = [Data_Per_Segment{theIdx}];
        Data_Per_ContrastLevel_Mean{ii}(:, rrun) = mean(Data_Per_ContrastLevel{ii, rrun}, 2);
    end
end

% Make aggregate plots
RGBCols = [252, 187, 161 ; ...
    252, 146, 114 ; ...
    251, 106, 74 ; ...
    222, 45, 38; ...
    165, 15, 21];

% Plot the time series
timeSeriesFig = figure;
timeVector = (1:(durIdx+1))/1000;
for ii = 1:NContrastLevels
    Data_Per_ContrastLevel_xrun_Mean = mean(Data_Per_ContrastLevel_Mean{ii}, 2);
    Data_Per_ContrastLevel_xrun_SEM = std(Data_Per_ContrastLevel_Mean{ii}, [], 2)/sqrt(NRuns);
    
    hold on;
    shadedErrorBar(timeVector, Data_Per_ContrastLevel_xrun_Mean, Data_Per_ContrastLevel_xrun_SEM);
    h(ii) = plot(timeVector, Data_Per_ContrastLevel_xrun_Mean, 'Color', RGBCols(ii, :)/255, 'LineWidth', 1.5);
end

% Set up a legend
for ii = 1:NContrastLevels
    legendLabels{ii} = [num2str(theContrastsScaled(ii)*100, '%g') '%'];
end
legend(h, legendLabels, 'Location', 'SouthEast'); legend boxoff;

% Tweak the plot further
title({protocol [strrep(subjectID, '_', '\_') '-' dateID ', \pm1SEM (runs)']});
xlim([0 13]);
ylim([-0.5 0.2]);
xlabel('Time [sec]');
ylabel('Pupil amplitude [pct change]');
set(gca, 'TickDir', 'out'); box off;
pbaspect([1 1 1]);

% Save figure
set(timeSeriesFig, 'PaperPosition', [0 0 4 4]);
set(timeSeriesFig, 'PaperSize', [4 4]);
saveas(timeSeriesFig, fullfile(outPath, [subjectID '-' protocol '-' dateID '_TimeSeries.png']), 'png');
close(timeSeriesFig);

% Plot the CRF
NSecondsStim = 3;
minWindow = NSecondsStim*params.ResamplingFineFreq-1;
crfFig = figure;
for ii = 1:NContrastLevels
    % Find the maximal pupil constriction
    Data_Per_ContrastLevel_xrun_MinMean(ii) = mean(min(Data_Per_ContrastLevel_Mean{ii}(1:minWindow, :)));
    Data_Per_ContrastLevel_xrun_MinSEM(ii) = std(min(Data_Per_ContrastLevel_Mean{ii}(1:minWindow, :)))/sqrt(NRuns);
    
end
%
errorbar(log10(theContrastsScaled*100), -Data_Per_ContrastLevel_xrun_MinMean, Data_Per_ContrastLevel_xrun_MinSEM, '-k'); hold on;
for ii = 1:NContrastLevels
    plot(log10(theContrastsScaled(ii)*100), -Data_Per_ContrastLevel_xrun_MinMean(ii), 'sk', 'MarkerFaceColor', RGBCols(ii, :)/255)
end
set(gca, 'XTick', log10(theContrastsScaled*100), 'XTickLabel', theContrastsScaled*100);

xlabel('Contrast [pct]');
ylabel('Minimum pupil constriction [pct]');
ylim([0 0.5]);
set(gca, 'TickDir', 'out'); box off;
pbaspect([1 1 1]);
title({protocol [strrep(subjectID, '_', '\_') '-' dateID ', \pm1SEM (runs)']});
% Save figure
set(crfFig, 'PaperPosition', [0 0 4 4]);
set(crfFig, 'PaperSize', [4 4]);
saveas(crfFig, fullfile(outPath, [subjectID '-' protocol '-' dateID '_CRF.png']), 'png');
close(crfFig);