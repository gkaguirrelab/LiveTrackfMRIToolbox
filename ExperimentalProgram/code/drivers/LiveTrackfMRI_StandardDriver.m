function params = LiveTrackfMRI_StandardDriver(expt)
% params = LiveTrackfMRI_StandardDriver(expt)
%
% Do the eye tracking here and assign to params
%
% For now, we just assign params to be the empty matrix.
params = [];

vidName = fullfile(expt.subjectDataDir, [expt.obsIDAndRun '.avi']);

%% find  Livetrack
% data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
LiveTrackHIDcomm(deviceNumber,'end'); %stop tracking
% video recording
vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
src = getselectedsource(vid); 

%% initialize
fprintf('\n Press spacebar to initialize LiveTrack.');
pause;
%video recording
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
firstTTL = true;
ii = 1;
log = true;
TimerFlag = false;

fprintf('\n LiveTrack: Listening...');

%% logging
persistent buffer
while log
    PsychHID('ReceiveReports',deviceNumber);
    [reports]=PsychHID('GiveMeReports',deviceNumber);
    buffer = [buffer reports];
    R = HID2struct(buffer);
    Report = R;
    R = 0;
    [reports] = [0];
    ii = ii+1;
    if Report(end).Digital_IO1 == 1 && firstTTL
        trigger(vid);
        firstTTL = false;
        fprintf('\n TTL detected! \n');
        %start timer
        TimerFlag = true;
    end
    if TimerFlag == true
        tic
        while toc < expt.recTimeInSecs * 1.5 %buffer required to record the exact amount of seconds
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
        display('LiveTrack:stopping...');
        log = false;
    end
end
% stop video e data recording
LiveTrackHIDcomm(deviceNumber,'end');
stop(vid);
stoppreview(vid);
closepreview(vid);

params.Report = Report;
