%% Load the data
clearvars

% Set some parameters
params.TRDurSecs = 0.8; % secs
params.NTRsExpected = 560; % #
params.LiveTrackSamplingRate = 60; % Hz
params.ResamplingFineFreq = 1000; % 1 msec
params.TimeVectorFine = 0:(1/params.ResamplingFineFreq):((params.NTRsExpected*params.TRDurSecs)-(1/params.ResamplingFineFreq));
params.BlinkWindowSample = -10:10; % Samples surrounding the blink event 

exptPath = '/Users/mspits/Dropbox (Aguirre-Brainard Lab)/MELA_data/MelanopsinMRMaxLMSCRF/HERO_asb1/060816/';
for i = 1
    %%
    %%%%% EYE TRACKING DATA %%%%%
    % Load the eye tracking data 
    Data_LiveTrack = load(fullfile(exptPath, 'EyeTrackingFiles', ['HERO_asb1-MelanopsinMRMaxLMSCRF-' num2str(i, '%02.f') '.mat']));
    
        % Find cases in which the TTL pulse signal was split over the two
    % samples, and remove the second sample.
    Data_LiveTrack_TTLPulses_raw = [Data_LiveTrack.params.Report.Digital_IO1];
    tmpIdx = strfind(Data_LiveTrack_TTLPulses_raw, [1 1]);
    Data_LiveTrack_TTLPulses_raw(tmpIdx) = 0;
    
    % We reconstruct the data set collected at 60 Hz.
    Data_LiveTrack_TTLPulses = [];
    Data_LiveTrack_PupilDiameter = [];
    Data_LiveTrack_IsTracked = [];
    for rr = 1:length(Data_LiveTrack.params.Report)
        Data_LiveTrack_TTLPulses = [Data_LiveTrack_TTLPulses Data_LiveTrack_TTLPulses_raw(rr) 0];
        
        % We use the pupil width as the index of pupil diameter
        Data_LiveTrack_PupilDiameter = [Data_LiveTrack_PupilDiameter Data_LiveTrack.params.Report(rr).PupilWidth_Ch01 ...
            Data_LiveTrack.params.Report(rr).PupilWidth_Ch02];
        Data_LiveTrack_IsTracked = [Data_LiveTrack_IsTracked Data_LiveTrack.params.Report(rr).PupilTracked_Ch01 ...
            Data_LiveTrack.params.Report(rr).PupilTracked_Ch02];
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
    Data_LiveTrack_PupilDiameter_FineMasterTime = interp1(TimeVectorLinear, ...
        Data_LiveTrack_PupilDiameter, params.TimeVectorFine);
    Data_LiveTrack_IsTracked_FineMasterTime = interp1(TimeVectorLinear, ...
        Data_LiveTrack_IsTracked, params.TimeVectorFine, 'nearest'); % Use NN interpolation for the binary tracking state
    
    %%
    %%%%% Stimulus data %%%%%
    % Load the stimulus data 
    Data_Stimulus = load(fullfile(exptPath, 'MatFiles', ...
        ['HERO_asb1-MelanopsinMRMaxLMSCRF-' num2str(i, '%02.f') '.mat']));
    
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
    
    %% We now have four variables of interest
    %   Data_Stimulus_Segment_FineMasterTime <- contains the segment index starting at a given time sample
    %   Data_LiveTrack_IsTracked_FineMasterTime <- Binary array indicating tracking state
    %   Data_LiveTrack_PupilDiameter_FineMasterTime <- Pupil diameter
    %   params.TimeVectorFine <- Time vector in TR time
    
    %% Remove blinks from the pupil data
    
    plot(Data_LiveTrack_PupilDiameter);
    Data_LiveTrack_BlinkIdx = [];
    for rr = 1:length(params.BlinkWindowSample)
        Data_LiveTrack_BlinkIdx = [Data_LiveTrack_BlinkIdx find(~Data_LiveTrack_IsTracked_FineMasterTime)+params.BlinkWindowSample(rr)];
    end
    Data_LiveTrack_BlinkIdx = unique(Data_LiveTrack_BlinkIdx);
Data_LiveTrack_PupilDiameter_FineMasterTime(Data_LiveTrack_BlinkIdx) = NaN;

    % Interpolate the elements
    Data_LiveTrack_PupilDiameter_FineMasterTime(isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)) = interp1(params.TimeVectorFine(~isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)), Data_LiveTrack_PupilDiameter_FineMasterTime(~isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)), params.TimeVectorFine(isnan(Data_LiveTrack_PupilDiameter_FineMasterTime)));

    %% Low-pass filtering the pupil data
    % For each 
    Fs = params.ResamplingFineFreq;
    NSamps = length(Data_LiveTrack_PupilDiameter_FineMasterTime);
    y_fft = abs(fft((Data_LiveTrack_PupilDiameter_FineMasterTime-mean(Data_LiveTrack_PupilDiameter_FineMasterTime))./(mean(Data_LiveTrack_PupilDiameter_FineMasterTime))));            %Retain Magnitude
    y_fft = y_fft(1:NSamps/2);      %Discard Half of Points
    f = Fs*(0:NSamps/2-1)/NSamps;   %Prepare freq data for plot
    plot(f, y_fft);
    xlim([0 0.1]);
    xlabel('Frequency [Hz]');
end



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