function [Report] = GetDataVideo

% Usage
% savePath = '/Users/giulia/Desktop/TEST';
% TRnum = Inf OR num of TRs


%% set saving path and names
clc

formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
vidName = ['LiveTrackVIDEO_' timestamp];
reportName = ['LiveTrackREPORT_' timestamp '.mat'];


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
frameRate = 30; %default fps
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile('/Users/giulia/Desktop/TEST/',vidName), 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;
% set manual trigger
triggerconfig(vid, 'manual') %change to appropriate trigger configuration
preview(vid);
[reports] = [0];
LiveTrackHIDcomm(deviceNumber,'end');
PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
LiveTrackHIDcomm(deviceNumber,'begin');
start(vid); %initialize video ob
firstTTL = true;
recTime = 60; %in seconds
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
        t = timer('TimerFcn',@timerFun,'StartDelay',recTime);
        t.UserData = true;
        start(t);
        while get(t,'UserData')
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
        log = t.UserData;
        stop(t);
        delete(t);
    end
end

LiveTrackHIDcomm(deviceNumber,'end');
stop(vid);
stoppreview(vid);



closepreview(vid);
save((fullfile('/Users/giulia/Desktop/TEST/',reportName)), 'Report');
fprintf('Matfile and video saved.\n');





function timerFun(obj,evt)
display('LiveTrack:stopping...');
log = false;
set(obj,'UserData',false);


