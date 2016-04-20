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
vid = videoinput('macvideo', 1,  'YUY2_320x240'); %'YCbCr422_1280x720');
src = getselectedsource(vid);
%% initialize
%video recording
vid.FramesPerTrigger = 1;
frameRate = 30; %default fps
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile(savepath,vidName), 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;
% data collection
err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));

fprintf('\n Press spacebar to initialize LiveTrack.');
pause;
R = LiveTrackHIDcomm(deviceNumber,'begin');
t = 0;
while t == 0
    R = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
    if R.Digital_IO1 == 1
        fprintf('\n TTL detected!');
        err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
        R = LiveTrackHIDcomm(deviceNumber,'continue');
        fprintf('\n Press spacebar to stop data collection and save matfile.');
        pause;
        R = LiveTrackHIDcomm(deviceNumber,'return all');
        t = 1;
    else
      continue  
    end
end
LiveTrackHIDcomm(deviceNumber,'end');
save((fullfile(savepath, reportName)), 'R');
fprintf('Matfile saved.\n');

