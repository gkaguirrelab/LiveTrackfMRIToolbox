function [timeBase] = getPupilTrackTimebase(params)

% <Description of what the function does>
%
%   Usage:
%       [timebase] = getPupilTrackTimebase(params)
%
%   Required inputs:
%       params.<fill in this portion>
%
%   Defaults:
%       params.<fill in this portion>
%
%
%   Written by ...


%%%%%%%%%%%% THIS WILL GO SOMEWHERE ELSE
%% Set defaults
% Get user name
[~, tmpName]            = system('whoami');
userName                = strtrim(tmpName);
% Set Dropbox directory
dbDir                   = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab'];
% Set the subject / session / run
sessName                = 'session1_restAndStructure';
subjName                = 'TOME_3007';
sessDate                = '101116';
reportName              = 'rfMRI_REST_AP_run01_report.mat';
videoName               = 'rfMRI_REST_AP_run01_raw.mov';
outVideoFile            = fullfile('~','testVideo.avi');
outMatFile              = fullfile('~','testMat.mat');
numTRs                  = 420;
acqRate                 = 1/30; % pupilTrack video frameRate in sec
ltRes                   = [360 240]; % resolution of the LiveTrack video (half original size)
ptRes                   = [400 300]; % resolution of the pupilTrack video
ltThr                   = 0.1; % threshold for liveTrack glint position
ylims                   = [0.25 0.75];
%% Set the session and file names
sessDir                 = fullfile(dbDir,'TOME_data',sessName,subjName,sessDate,'EyeTracking');
reportFile              = fullfile(sessDir,reportName);
videoFile               = fullfile(sessDir,videoName);

%% Get the LiveTrack and raw video data
% LiveTrack
liveTrack               = load(reportFile);

% pupilTrack
% check if a tracking data already exist. If not, do the tracking.


params.inVideo          = videoFile;
params.outVideo         = outVideoFile;
params.outMat           = outMatFile;
[pupil,glint]           = trackPupil(params);


%%%%%%%%%%%% /THIS WILL GO SOMEWHERE ELSE

% new inputs
% metadata


%% Perform some sanity checks on the LiveTrack report
% check if the frameCount is progressive
frameCountDiff          = unique(diff([liveTrack.Report.frameCount]));
assert(numel(frameCountDiff)==1,'LiveTrack frame Count is not progressive!');

% verify that the correct amount of TTLs has been recorded (for fMRI runs)
if ~isnan(numTRs)
    [TTLPulses]             = CountTTLPulses (liveTrack.Report);
    assert(TTLPulses==numTRs,'LiveTrack TTLs do not match TRs!');
    % verify that the TTLs are correctly spaced, assuming that the acquisition
    % rate is 30 Hz
    
    %%% need to add this sanity check %%%
end

%% Use the X position of the glint to align data
% LiveTrack
%   average the two channels, output is at 30Hz
ltSignal                = mean([...
    [liveTrack.Report.Glint1CameraX_Ch01];...
    [liveTrack.Report.Glint1CameraX_Ch02]]);
ltNorm                  = ltSignal / ltRes(1);
% Remove poor tracking
ltDiff                  = [0 diff(ltNorm)];
ltNorm(abs(ltDiff) > ltThr)  = nan; % remove glint positions < ltThr

% pupilTrack
ptSignal                = glint.X;
ptNorm                  = (ptSignal / ptRes(1))';
%% Cross correlate the signals to compute the delay
% cross correlation doesn't work with NaNs, so we change them to zeros
ltCorr                  = ltNorm;
ptCorr                  = ptNorm;
ltCorr(isnan(ltNorm))   = 0 ;
ptCorr(isnan(ptNorm))   = 0 ;
% set vectors to be the same length (zero pad the END of the shorter one)
if length(ptCorr) > length(ltCorr)
    ltNorm              = [ltNorm,zeros(1,(length(ptCorr) - length(ltCorr)))];
    ltCorr              = [ltCorr,zeros(1,(length(ptCorr) - length(ltCorr)))];
else
    ptNorm              = [ptNorm,zeros(1,(length(ltCorr) - length(ptCorr)))];
    ptCorr              = [ptCorr,zeros(1,(length(ltCorr) - length(ptCorr)))];
end
% calculate cross correlation and lag array
[r,lag]                 = xcorr(ltCorr,ptCorr);

% when cross correlation of the signals is max the lag equals the delay
[~,I]                   = max(abs(r));
delay                   = lag(I); % unit = [number of samples]

% shift the signals by the 'delay'
ltAligned               = ltNorm; % lt is not shifted
ltAligned(ltAligned==0) = nan;
ptAligned               = [zeros(1,delay),ptNorm(1:end-delay)];
ptAligned(ptAligned==0) = nan;

%% assign a common timeBase
% since ltSignal was not shifted and ptSignal is now aligned, we can assign
% a common timeBase
timeBaseTMP                = 1:length(ltAligned);
% get the first from liveTrack.Report
allTTLs                 = find([liveTrack.Report.Digital_IO1] == 1);
% if present, set the first TR to time zero
if ~isempty(allTTLs)
    firstTR                  = allTTLs(1);
    timeBase.lt       = (timeBaseTMP - firstTR) * acqRate; %liveTrack timeBase in [sec]
else
    timeBase.lt       = (timeBaseTMP - 1) * acqRate;
end
    timeBase.pt       = timeBase.lt + delay * acqRate; %pupilTrack timeBase in [sec]

%%
% %% Plot the cross correlation results
% fullFigure;
% % before alignment
% subplot(2,1,1)
% plot(ltNorm, 'LineWidth',2);
% hold on;
% plot(ptNorm, 'LineWidth',2)
% grid on
% ylabel('glint X (normalized)')
% xlabel('Frames')
% legend ('liveTrack','pupilTrack')
% title ('Before alignment')
% ylim(ylims);
% % after alignment
% subplot(2,1,2);
% plot(ltAligned, 'LineWidth',2);
% hold on;
% plot(ptAligned, 'LineWidth',2)
% grid on
% ylabel('glint X (normalized)')
% xlabel('Frames')
% legend ('liveTrack','pupilTrack')
% title(['After alignment (shift = ' num2str(delay) ' frames)']);
% ylim(ylims);