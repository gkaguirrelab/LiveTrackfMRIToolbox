%% TEST TRACKING PARAMS

% this script is to test tracking params. It will perform the tracking on
% the first 3000 frames of a video.

%% paths
% Set Dropbox directory
%get hostname (for melchior's special dropbox folder settings)
[~,hostname] = system('hostname');
hostname = strtrim(lower(hostname));
if strcmp(hostname,'melchior.uphs.upenn.edu')
    dropboxDir = '/Volumes/Bay_2_data/giulia/Dropbox-Aguirre-Brainard-Lab';
else
    % Get user name
    [~, tmpName] = system('whoami');
    userName = strtrim(tmpName);
    dropboxDir = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab'];
end


% for eye tracking
params.projectFolder = 'TOME_data';
params.outputDir = 'TOME_processing';
params.eyeTrackingDir = 'EyeTracking';
params.analysisDir = 'TOME_analysis';

% subject
params.projectSubfolder = 'session2_spatialStimuli';
params.subjectName = 'TOME_3014';
params.sessionDate = '021717';


% run
params.runName = 'tfMRI_FLASH_AP_run01';

% calibration
calName = 'GazeCal01_LTcal.mat';

% file Names
reportName = [params.runName '_report.mat'];
ptRescaledName = [params.runName '_rescaledPupil.mat'];
ptTrackName = [params.runName '_pupilTrack.mat'];
responseName = [params.runName '_response.mat'];


%% find deinterlaced video in processing folder
processingDir = fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking');

%% params for tracking
outDir = fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking');
params.acqRate = 60;
params.pupilFit = 'newEllipse';
% params.pupilFit = 'circle';
params.inVideo = fullfile(outDir,[params.runName '_60hz.avi']);
params.outVideo = fullfile(outDir,[params.runName '_fullEllipse.avi']);
params.outMat = fullfile(outDir, [params.runName '_fullEllipse.mat']);
params.ellipseThresh   = [0.963 0.9];
params.threshVals = [0.06 0.999];
params.cutPupil = 0;


params.forceNumFrames = 4000;
% [pupil , iris, eyelid] = irisFit (params);
trackPupil(params);




