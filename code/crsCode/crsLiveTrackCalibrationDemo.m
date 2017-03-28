function crsLiveTrackCalibrationDemo(viewDist, screenSize, Window1ID, Window2ID)


%% user input

Screen('Preference', 'SkipSyncTests', 1); % uncomment for testing only

if nargin<4,
    Window1ID = 1;    % ID of controller monitor (1 should be the primary monitor on Windows)
end
if nargin<3,
    Window2ID = 2;    % ID of stimulus monitor (2 should be the secondary monitor on Windows)
end
if nargin<2,
    screenSize = 17;    % screen size in inches
end
if nargin<1,
    viewDist = 500;     % view distance in mm
end

%% setup
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
save('LTdat.mat','pupil','glint','targets')
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
save('LTcal.mat','CalMat','Rpc')
% load('LTcal.mat','CalMat','Rpc')

%% Draw a dot at the gaze position (using calibration from raw data at host)

crsLiveTrackShowGazePositionHID(deviceNumber, CalMat, Rpc, viewDist, screenSize, NoOfGlints, Window1ID, Window2ID); 

