function LiveTrack_GazeCalibration(viewDist, screenSize, Window1ID, Window2ID,savePath)
% Calibration function for LiveTrack fMRI pupil tracking for experiments
% that display stimuli on an external screen. DO NOT USE TO CALIBRATE IR
% CAMERA WHEN USING EYEPIECE.
%
% Before running calibration, make sure that the LiveTrack camera is
% properly set up (ref. LiveTrack fMRI user manual).
% 
% Includes: setup, collect calibration data, calculate calibration matrix,
% visual test to verify calibration was succesful.
%
% Usage: 
% viewDist = 500 %viewing distance in mm 
% screenSize = 19 %diagonal of the screen in inches
% outDir = 'path_to_output_dir';
% LiveTrackCalibration_screen(viewDist, screenSize, outDir)
%
%
% LiveTrackCalibration_screen(viewDist, screenSize, outDir, Window1ID, Window2ID)
% 
% 03/11/16 GF - Based on crsLiveTrackCalibrationDemo.
%% Input params (demo mode)

% Screen('Preference', 'SkipSyncTests', 1); % uncomment for testing only
if ~exist ('viewDist','var')
    viewDist = 600;    % distance in mm from the screen
end
if ~exist ('screenSize','var')
    screenSize = 32;    % Diagonal of the screen in inches
end

if ~exist ('Window1ID','var')
    Window1ID = 0;    % ID of controller monitor (1 should be the primary monitor on Windows)
end
if ~exist ('Window2ID','var')
    Window2ID = 1;    % ID of stimulus monitor (2 should be the secondary monitor on Windows)
end

if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop');
end


% set timestamp
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);



%% IR Camera setup
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
if ~isempty(strfind(type,'AV')),
    NoOfGlints = 1;% one for LiveTrack for fMRI
    disp('Device type "LiveTrack AV" found!');
elseif ~isempty(strfind(type,'FM')),
	NoOfGlints = 2;% or two for LiveTrack-FM
	disp('Device type "LiveTrack FM" found!');
else
    error('Must be LiveTrack FM or LiveTrack AV device type!');
end

%% collect calibration data
[pupil, glint, targets, Rpc] = crsLiveTrackGet9PointFixationDataHID(deviceNumber, viewDist, screenSize, NoOfGlints, Window1ID, Window2ID);
file1 = fullfile(savePath,['LTdat_' timestamp '.mat']);
save(file1,'pupil','glint','targets')
% load('LTdat.mat','pupil','glint','targets')

%% calculate calibration matrix parameters
disp(' ');
disp('Please wait while data is beeing calibrated...');
disp(' ');
CalMat = crsLiveTrackCalculateCalibrationMatrix(pupil, glint, targets, viewDist, Rpc);

data = crsLiveTrackCalibrateRawData(CalMat, Rpc, pupil, glint);

figure; hold on;
% plot each true and tracked target position. Red cross means target
% position and blue means tracked gaze position.
for i = 1:length(data(:,1))
    plot(targets(i,1), targets(i,2),'rx');
    plot(data(i,1), data(i,2),'bx');
    plot([targets(i,1) data(i,1)], [targets(i,2) data(i,2)],'g');
end
errors = sqrt((targets(:,1)-data(:,1)).^2+(targets(:,2)-data(:,2)).^2); 
accuracy = mean(errors(~isnan(errors)));
title(['Average error: ',num2str(accuracy),' mm'])
xlabel('Horizontal position (mm)');ylabel('Vertical position (mm)');
legend('Target position','Estimated gaze position')
file2= fullfile(savePath,['LTcal_' timestamp '.mat']);
save(file2,'CalMat','Rpc')
% load('LTcal.mat','CalMat','Rpc')

%% Draw a dot at the gaze position (using calibration from raw data at host)
% this is to verify the calibration was successful: the function shows an
% image of some apples on the stimulus monitor for the subject to look at
% and a dot is drawn at the location of at the estimated gaze position. A
% copy of this is drawn to a smaller window on the control monitor. A quick
% offset calibration can be made by pressing minus (-) on the numeric keys
% of the keyboard. The subject then has to look at the dot in the centre
% while an offset is being calculated. This might have to be repeated a few
% times to make it right.
crsLiveTrackShowGazePositionHID(deviceNumber, CalMat, Rpc, viewDist, screenSize, NoOfGlints, Window1ID, Window2ID); 

