function params = LiveTrack_ScaleCalibration(scaleDiams, recTime, savePath,GetRawVideo)

% This function is used to calibrate the size of the pupil tracked with a
% CRS LiveTrackAV unit. It needs to be run after each session, pointing the
% camera towards at least 3 different diameters on the calibration stick,
% using the same focal distance used during the experiment (i.e. the
% calibration stick must be placed so that the black dots appear in focus
% as the subject eye did during the experiment).

% HOW TO USE:
% At the end of the session:
% - remove the LiveTrackAV from the head mount, making sure not to screw in or
% out the lens.
% - place the calibration stick to a flat surface.
% - point the camera towards the calibration stick, approximately 10-12
% cm apart.
% - run this function.
% - select at least 3 diameters as reference for the calibration.
% - adjust the camera/calibration stick position for every calibration dot
% so that they appear in focus (DO NOT ADJUST THE FOCUS USING THE LENS
% SCREW)
% - collect the calibration videos (suggested length: 10 seconds)


% May 2016 - Giulia Frazzetta, Manuel Spitschan: written 
% July 2016 - GF : updated

%% Set variables
% Pre allocate params
params = [];

%% Input params (demo mode)
if ~exist('scaleDiams','var')
    scaleDiams = [3 4 5];
end

if ~exist('recTime', 'var')
    recTime = 10;
end

if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop');
end

if ~exist ('GetRawVideo', 'var')
    GetRawVideo = true;
end
% set timestamp
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);

%% find  and set Livetrack
closeLiveTrack;
% locate LiveTrack
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

%% video recording for every sample diameter
params.pupilDiameterMmGroundTruth = scaleDiams;
for ii = 1:length(scaleDiams)
    
    % video name setting
    vidName = fullfile(savePath, [ 'ScaleCalibration_' num2str(scaleDiams(ii)) 'mm_' timestamp '.avi']);
    RawVidName = fullfile(savePath, [ 'RawScaleCal' num2str(scaleDiams(ii)) 'mm' timestamp '.avi']);
    % locate video source (LiveTrack webcam interface)
    vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
    src = getselectedsource(vid);
    
    % prompt the user to adjust the camera over the correct target and
    % initialize LiveTrack
    fprintf('>> Set up camera to show target of <strong>%g mm </strong>...', scaleDiams(ii));
    fprintf('\nPress spacebar to initialize LiveTrack. The preview window will appear. ');
    pause;
    
    %video recording settings
    vid.FramesPerTrigger = Inf;
    diskLogger = VideoWriter(vidName, 'Motion JPEG AVI');
    diskLogger.FrameRate = 10;  % Note that this is the default LiveTrack Camera interface frameRate.
    diskLogger.Quality = 75;
    vid.DiskLogger = diskLogger;
    vid.LoggingMode = 'disk';
    triggerconfig(vid, 'manual')
    
    % verify that tracking is good with the preview window
    preview(vid);
    fprintf('\nMake sure that the calibration dot is correctly tracked, then press spacebar to close preview.');
    pause
    stoppreview(vid);
    closepreview(vid);
    
    % initialize video object for recoding
    start(vid);
    
    % initialize data acquisition
    [reports] = [0];
    PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
    
    fprintf('\n Press spacebar to start recording.');
    pause;
    
    % initialize the buffer
    buffer = [];
    
    % record calibration video and data
    if recTime == Inf
        if GetRawVideo
            rawScriptPath = which('RawVideoRec.scpt');
            [status, echo2] = system(sprintf(['osascript ' rawScriptPath ' %s %s %s'], savePath, RawVidName, num2str(1000)));      
        end
        trigger(vid);
        LiveTrackHIDcomm(deviceNumber,'begin');
        PsychHID('ReceiveReports',deviceNumber);
        [reports]=PsychHID('GiveMeReports',deviceNumber);
        buffer = [buffer reports];
        R = HID2struct(buffer);
        Report = R;
        R = 0;
        [reports] = [0];
        fprintf('\n Press spacebar to stop recording.');
        pause;
    else
        if GetRawVideo
            rawScriptPath = which('RawVideoRec.scpt');
            [status, echo2] = system(sprintf(['osascript ' rawScriptPath ' %s %s %s'], savePath, RawVidName, num2str(recTime)));
        end
        trigger(vid);
        LiveTrackHIDcomm(deviceNumber,'begin');
        display('LiveTrack: recording...');
        tic
        while toc < recTime
            PsychHID('ReceiveReports',deviceNumber);
            [reports]=PsychHID('GiveMeReports',deviceNumber);
            buffer = [buffer reports];
            R = HID2struct(buffer);
            Report = R;
            R = 0;
            [reports] = [0];
        end
        toc % Elapsed time is displayed
    end
    
    % end data and video recording
    LiveTrackHIDcomm(deviceNumber,'end');
    pause(0.5);
    stop(vid);
    
    
    % Make a copy of the report
    params.ReportRaw{ii} = Report;
    
    % clean the video object
    delete(vid)
    close(gcf)
    
    
    % Calculate the conversion factors for width and height independently.
    params.cameraUnitsToMmWidth(ii) = mean([params.ReportRaw{ii}.PupilWidth_Ch01]) / params.pupilDiameterMmGroundTruth(ii);
    params.cameraUnitsToMmHeight(ii) = mean([params.ReportRaw{ii}.PupilHeight_Ch01]) / params.pupilDiameterMmGroundTruth(ii);
end

params.cameraUnitsToMmWidthMean = mean(params.cameraUnitsToMmWidth);
params.cameraUnitsToMmHeightMean = mean(params.cameraUnitsToMmHeight);

% display the conversion factors
fprintf('>> Final conversion factor (camera units to mm - width): <strong>%.2f</strong>\n', params.cameraUnitsToMmWidthMean);
fprintf('>> Final conversion factor (camera units to mm - height): <strong>%.2f</strong>\n', params.cameraUnitsToMmHeightMean);
closeLiveTrack;