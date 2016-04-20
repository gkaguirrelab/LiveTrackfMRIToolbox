%% set saving path and names
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
vidName = ['VIDEO_' timestamp '.avi '];
reportName = ['REPORT_' timestamp '.mat'];
savePath = '/Users/giulia/Desktop/TEST';

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
triggerconfig(vid, 'manual') %change to appropriate trigger configuration
vid.FramesPerTrigger = Inf;
frameRate = 30; %default fps
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile('/Users/giulia/Desktop/TEST/',vidName), 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;

% data collection
err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
preview(vid);
fprintf('\n Press spacebar to enter listening mode.');
pause;
R = LiveTrackHIDcomm(deviceNumber,'begin');
start(vid); %initialize video ob
t = 0;
fprintf('\n LiveTrack> Listening...');
while t == 0
    R = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
    if R.Digital_IO1 == 1
        err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
        R = LiveTrackHIDcomm(deviceNumber,'continue');
        trigger(vid);
        fprintf('\n TTL detected!');
        fprintf('\n Press spacebar to stop data collection and save matfile and video.');
        pause;
        R = LiveTrackHIDcomm(deviceNumber,'return all');
        stop(vid);
        stoppreview(vid);
        t = 1;
    else
      continue  
    end
end
LiveTrackHIDcomm(deviceNumber,'end');
closepreview(vid);
save((fullfile('/Users/giulia/Desktop/TEST/',reportName)), 'R');
fprintf('Matfile and video saved.\n');

