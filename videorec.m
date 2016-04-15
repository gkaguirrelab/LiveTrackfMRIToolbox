%% set video name and acquisition mode
vidName = 'TESTvid10.avi';

manualStop = 1;
recLength = 10 ; %in seconds

%% find and set camera for video recording
vid = videoinput('macvideo', 1,  'YUY2_320x240'); %'YCbCr422_1280x720');
src = getselectedsource(vid);

vid.FramesPerTrigger = 1;
frameRate = 30; %default fps

vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile('/Users/giulia/Desktop/TEST/',vidName), 'Motion JPEG AVI');

vid.DiskLogger = diskLogger;

%% find IR camera for data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

%% acquisition

if manualStop
    vid.FramesPerTrigger = Inf;
    preview(vid);
    triggerconfig(vid, 'manual') %change to appropriate trigger configuration
    start(vid); %initialize video ob
   pause;  
        trigger(vid);
        %start data acquisition
       crsLiveTrackHIDcomm(deviceNumber,'begin')
  pause;  
    stop(vid);
    R = crsLiveTrackHIDcomm(deviceNumber,'return all')
    pause;
    stoppreview(vid);
    
    
    
else
    vid.FramesPerTrigger = recLength * frameRate;
    preview(vid);
    pause;
    start(vid);
     %start data acquisition
    pause;
    stoppreview(vid);
    
end


