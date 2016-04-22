function [Report] = GetDataVideo

% Usage
% savePath = '/Users/giulia/Desktop/TEST';
% TRnum = Inf OR num of TRs

%% set saving path and names
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
stopTime = Inf;
ii = 1;
log = true;
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
        stopTime = datenum(clock + [0, 0, 0, 0, 0, 20]);
    end
    if datenum(clock) > stopTime
         log = false;
    end
end
LiveTrackHIDcomm(deviceNumber,'end');
stop(vid);
stoppreview(vid);



closepreview(vid);
save((fullfile('/Users/giulia/Desktop/TEST/',reportName)), 'Report');
fprintf('Matfile and video saved.\n');

