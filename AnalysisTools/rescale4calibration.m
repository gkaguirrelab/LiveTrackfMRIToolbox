function [RescaledPupil,RescaledGlint] = rescale4calibration(params,dropboxDir)
% DECOMMISSIONED FUNCTION

% rescale values for calibration



% %% DEMO - uncomment and run this session for an usage example
%
% % Get user name
% [~, tmpName]            = system('whoami');
% userName                = strtrim(tmpName);
% % Set Dropbox directory
% dropboxDir                   = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab'];
% % Set the subject / session / run
% params.outputDir        = 'TOME_processing';
% params.projectFolder    = 'TOME_processing';
% params.projectSubfolder = 'session2_spatialStimuli';
% params.eyeTrackingDir   = 'EyeTracking';
% params.subjectName      = 'TOME_3008';
% params.sessionDate      = '103116';
% params.runName          = 'tfMRI_MOVIE_AP_run02';
%
% params.ltRes            = [720 480] ./2; % resolution of the LiveTrack video (half original size)
% params.ptRes            = [400 300]; % resolution of the pupilTrack video

% [RescaledPupil,RescaledGlint] = rescale4calibration(params,dropboxDir)

%% set default params
if ~isfield(params,'ltRes')
    params.ltRes = [720 480] ./2;
end

if ~isfield(params,'ptRes')
    params.ptRes = [400 300];
end

%% Set the session and file names
if isfield(params,'projectSubfolder')
    pupilTrackFile = fullfile(dropboxDir,params.outputDir,...
        params.projectSubfolder,params.subjectName,params.sessionDate,params.eyeTrackingDir,[params.runName '_pupilTrack.mat']);
else
    pupilTrackFile = fullfile(dropboxDir,params.outputDir,...
        params.subjectName,params.sessionDate,params.eyeTrackingDir,[params.runName '_pupilTrack.mat']);
end

%% Load data
load(pupilTrackFile);

%% Rescale pupilTrack data to use LiveTrack calibration values
% coefficients determined as follows
% 1. normalize the signals with known ltRes and ptRes values
% 2. measure the median of the calibration measure from available scale
% calibration tracked both with liveTrack and pupilTrack algorithm (late
% subjects) to determine the adjusting factor.

sizeCoeff = 0.0117 ;
xCoeff = 0.001;
yCoeff = 0.001;

RescaledPupil.size = pupil.size * 0.9; 
RescaledPupil.X = pupil.X ;
RescaledPupil.Y = pupil.Y ;
RescaledGlint.X = glint.X;
RescaledGlint.Y = glint.Y ;

%% save out rescaled pupil track

if isfield(params,'projectSubfolder')
    save (fullfile(dropboxDir,params.outputDir,...
        params.projectSubfolder,params.subjectName,params.sessionDate,params.eyeTrackingDir,[params.runName '_rescaledPupil.mat']),'RescaledPupil','RescaledGlint');
else
    save (fullfile(dropboxDir,params.outputDir,...
        params.subjectName,params.sessionDate,params.eyeTrackingDir,[params.runName '_rescaledPupil.mat']),'RescaledPupil','RescaledGlint');
end
