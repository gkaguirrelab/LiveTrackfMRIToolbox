%% DEV_errorMetric

% looking for a coefficient to assess the accuracy of the tracking.

% CORRELATION strategy: load a *_pupilTrack.mat file. Given the tracking
% params, generate a bw image of the tracked pupil (background white,
% ellipse fitted to the pupil black). Correlate this image with the
% original one. Plot results. Later, do the same with a calibration dot
% video (we expect the correlation to be consistently high in that case).


%% clean

clear all
close all
clc


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
params.runName = 'tfMRI_RETINO_PA_run01';

ptTrackName = [params.runName '_pupilTrack.mat'];
videoName = [params.runName '_60hz.avi'];

% calibration
calName = 'GazeCal01_LTcal.mat';


%% load track data
trackData = load (fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking',ptTrackName));


%% load 60 Hz movie
inVideo = fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking',videoName);




disp('Loading video file and converting to standard format, may take a couple minutes...');
inObj                   = VideoReader(inVideo);
numFrames               = floor(inObj.Duration*inObj.FrameRate);
grayI                   = zeros([240 320 numFrames],'uint8');

% 
% % OVERRIDE NUMFRAMES
% numFrames = 3000;

% initialize correlation array
correlation = zeros(1,numFrames);

% Convert to gray, resize, crop to livetrack size
for i = 1:numFrames
    thisFrame           = readFrame(inObj);
    tmp                 = rgb2gray(thisFrame);
    tmp2        = imresize(tmp,[486 720]/2); %params.imageSize);
    tmp3 = imcrop(tmp2,[1 1 319 239]);%params.imageCrop);
    grayI(:,:,i) = tmp3;
end
disp('done!');

% ellipse params
ellipseParams = trackData.glint.ellipseParams;

%% cross correlate every frame with ellipse fit
for ii = 1:numFrames
    
    grayFrame = squeeze(grayI(:,:,i));
    
    % create a gray image of the ellipse fit
    bwFit = zeros([240 320]);
    
    eParams = ellipseParams(ii);
    if ii >1 && ~isnan(correlation(ii - 1))
        if isempty(eParams.status) && ~isempty(eParams.X0_in)
            [Xp, Yp] = calcEllipse(eParams, 360);
            idx = sub2ind([240 320], Xp, Yp);
            bwFit(idx) = 1;
            % fill the holes
            bwFit = imfill(bwFit,'holes');
            
            %     % invert (so that pupil is black)
            %     bwFit = imcomplement(bwFit);
            %
            % convert to gray
            grayFit = uint8(bwFit);
            
            % get correlation value for this frame
            correlation(ii) = (corr2(grayFrame,grayFit));
        else
            correlation (ii) = NaN;
        end
    else
        continue
    end
    
end

%% verify that those are blinks
blinkFrames =  find(isnan(correlation));

for jj = 1: length (blinkFrames)
     grayFrame = squeeze(grayI(:,:,blinkFrames(jj)));
     imshow (grayFrame)
end

