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
% video recording
vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
src = getselectedsource(vid);

%% initialize
fprintf('\n Press spacebar to initialize LiveTrack.');
pause;
%video recording
vid.FramesPerTrigger = Inf;
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
log = true;
TimerFlag = false;

bufferTime = 5;
fprintf('\n LiveTrack: Listening...');

%% logging
buffer = [];
while log
    PsychHID('ReceiveReports',deviceNumber);
    [reports]=PsychHID('GiveMeReports',deviceNumber);
    buffer = [buffer reports];
    R = HID2struct(buffer);
    Report = R;
    R = 0;
    [reports] = [0];
    if Report(end).Digital_IO1 == 1 && firstTTL
        trigger(vid);
        t0 = mglGetSecs;
        firstTTL = false;
        fprintf('\n First t received! \n');
        %start timer
        TimerFlag = true;
    end
    if TimerFlag == true
        while mglGetSecs-t0 < expt.recTimeInSecs+bufferTime %safety buffer
            PsychHID('ReceiveReports',deviceNumber);
            mglWaitSecs(1);
            %fprintf('\nLiveTrack: recording... ');
            [reports]=PsychHID('GiveMeReports',deviceNumber);
            buffer = [buffer reports];
            R = HID2struct(buffer);
            Report = R;
            R = 0;
            [reports] = [0];
        end
        fprintf('\nLiveTrack:stopping...');
        mglWaitSecs(3);
        log = false;
    end
end
tEnd = mglGetSecs;
% stop video e data recording
LiveTrackHIDcomm(deviceNumber,'end');
fprintf ('\nLiveTrack:saving data... ');
mglWaitSecs(5);
stop(vid);
stoppreview(vid);
closepreview(vid);

params.Report = Report;
params.tStartBlock = t0;
params.tEndBlock = tEnd;
fprintf('\n>> Total duration: <strong>%.2f</strong> (called for: %.2f)', params.tEndBlock-params.tStartBlock, expt.recTimeInSecs+bufferTime);

fprintf ('done.\n');
% cleanup
delete(vid);
close(gcf);
