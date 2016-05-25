function params = LiveTrackfMRI_ScaleCalibrationDriver(expt)
% params = LiveTrackfMRI_ScaleCalibrationDriver(expt)
%
%
%
% For now, we just assign params to be the empty matrix.
params = [];

% Enter the scale diameters
params.pupilDiameterMmGroundTruth = GetWithDefault('Enter pupil diameters on calibration stick you want to test. Use square brackets for multiple ones.', 5);

recTime = expt.recTimeInSecs;

%% find  Livetrack
% data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
% video recording

for ii = 1:length(params.pupilDiameterMmGroundTruth)
    vidName = fullfile(expt.subjectDataDir, [expt.obsIDAndRun '-scaleCalibration_' num2str(params.pupilDiameterMmGroundTruth(ii)) 'Mm.avi']);
    fprintf('>> Set up camera to show target of <strong>%g mm </strong>...', params.pupilDiameterMmGroundTruth(ii));
    % video recording
    vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
    src = getselectedsource(vid);
    
    %% find and set camera for video recording
    fprintf('\nPress spacebar to initialize LiveTrack... ');
    pause;
    
    
    %video recording settings
    vid.FramesPerTrigger = Inf;
    frameRate = 30; %default fps

    
    diskLogger = VideoWriter(vidName, 'Motion JPEG AVI');
    vid.DiskLogger = diskLogger;
    vid.LoggingMode = 'disk';
    
        
    % set manual trigger
    triggerconfig(vid, 'manual')
    preview(vid);
    start(vid); %initialize video ob
    
    [reports] = [0];
    PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
    
    
    fprintf('done!');
    fprintf('\n Press spacebar to start recording.');
    pause;
    
    %% acquisition
    %persistent buffer
    buffer = [];
    
    
    if recTime == Inf
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
        trigger(vid);
        LiveTrackHIDcomm(deviceNumber,'begin');
        tic
        while toc < recTime * 1.5 %buffer required to record the exact amount of seconds
            display('LiveTrack: recording...');
            pause(1);
            PsychHID('ReceiveReports',deviceNumber);
            [reports]=PsychHID('GiveMeReports',deviceNumber);
            buffer = [buffer reports];
            R = HID2struct(buffer);
            Report = R;
            R = 0;
            [reports] = [0];
        end
    end
    
    LiveTrackHIDcomm(deviceNumber,'end');
    pause(0.5);
    stop(vid);
    stoppreview(vid);
closepreview(vid);
    
    % Make a copy of the report
    params.ReportRaw{ii} = Report;
    
    % Calculate the conversion factors for width and height independently.
    params.cameraUnitsToMmWidth(ii) = mean([params.ReportRaw{ii}.LeftPupilWidth]) / params.pupilDiameterMmGroundTruth(ii);
    params.cameraUnitsToMmHeight(ii) = mean([params.ReportRaw{ii}.LeftPupilHeight]) / params.pupilDiameterMmGroundTruth(ii);
end

params.cameraUnitsToMmWidthMean = mean(params.cameraUnitsToMmWidth);
params.cameraUnitsToMmHeightMean = mean(params.cameraUnitsToMmHeight);

fprintf('>> Final conversion factor (camera units to mm - width): <strong>%.2f</strong>\n', params.cameraUnitsToMmWidthMean);
fprintf('>> Final conversion factor (camera units to mm - height): <strong>%.2f</strong>\n', params.cameraUnitsToMmHeightMean);