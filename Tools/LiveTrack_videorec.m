function LiveTrack_videorec(recTime, savepath)
% Records a video from the LiveTrack camera. If recTime=Inf, the user will
% stop the recording pressing the spacebar. Otherwise the recording will
% last recTime in seconds.
% Note that this function will show the video preview while recording. This
% could cause instability and crashes.

% May 2016 - Giulia Frazzetta: written 
%% for quick testing
if ~exist ('savepath', 'var')
    savepath = '/Users/giulia/Desktop/TEST/';
end

%% set video name
clc

formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
vidName = ['LiveTrackVIDEO_' timestamp];

vid = videoinput('macvideo', 1, 'YUY2_320x240');
src = getselectedsource(vid);
%% find and set camera for video recording
fprintf('\n Press spacebar to initialize LiveTrack.');
pause;
%video recording
vid.FramesPerTrigger = Inf;
frameRate = 10; %default fps for the livetrack
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile(savepath,vidName), 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;
% set manual trigger
triggerconfig(vid, 'manual')
preview(vid);

fprintf('\n Press spacebar to start recording.');
pause;

%% acquisition

if recTime == Inf
    trigger(vid);
    fprintf('\n Press spacebar to stop recording.');
    pause;
    stop(vid);
    pause;
    
else
    trigger(vid);
    tic
    while toc < recTime + 2 %buffer 
        toc
        pause(1);
    end
    fprintf('\n Stopping...');
    stop(vid);
    pause;
end

stoppreview(vid);
closepreview(vid);
% Clean the video object
delete(vid)
close(gcf)


