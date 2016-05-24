function params = LiveTrackfMRI_ScaleCalibrationDriver(expt)
% params = LiveTrackfMRI_ScaleCalibrationDriver(expt)
%
%
%
% For now, we just assign params to be the empty matrix.
params = [];

vidName = fullfile(expt.subjectDataDir, [expt.obsIDAndRun '-scaleCalibration.avi']);
recTime = expt.recTimeInSecs;

%% find  Livetrack
% data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
% video recording
vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
src = getselectedsource(vid);


%% find and set camera for video recording
fprintf('\n Press spacebar to initialize LiveTrack... ');
pause;

%video recording settings
vid.FramesPerTrigger = Inf;
frameRate = 30; %default fps
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(vidName, 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;
% set manual trigger
triggerconfig(vid, 'manual') 
preview(vid);
[reports] = [0];
PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
LiveTrackHIDcomm(deviceNumber,'begin');
start(vid); %initialize video ob
fprintf('done!');
fprintf('\n Press spacebar to start recording.');
pause;

%% acquisition
persistent buffer

if recTime == Inf
    trigger(vid);
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
    ii = 1;
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
        ii = ii+1;
    end
end

LiveTrackHIDcomm(deviceNumber,'end');
stop(vid);
stoppreview(vid);
closepreview(vid);

params.Report = Report;

