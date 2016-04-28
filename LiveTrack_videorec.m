function LiveTrack_videorec(recTime, savepath)
% Records a video from the LiveTrack camera. If recTime=Inf, the user will
% stop the recording pressing the spacebar. Otherwise the recording will
% last recTime in seconds.

%% for quick testing
if ~exist ('savepath', 'var')
    savepath = '/Users/giulia/Desktop/TEST/';
end

%% set video name
clc

formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
vidName = ['LiveTrackVIDEO_' timestamp];


%% find and set camera for video recording
fprintf('\n Press spacebar to initialize LiveTrack.');
pause;
%video recording
vid.FramesPerTrigger = Inf;
frameRate = 30; %default fps
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile(savepath,vidName), 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;
% set manual trigger
triggerconfig(vid, 'manual') %change to appropriate trigger configuration
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
    stoppreview(vid);
    closepreview(vid);
else
    trigger(vid);
    tic
    while toc < recTime * 1.5 %buffer required to record the exact amount of seconds
        display('LiveTrack: recording...');
        pause(1);
    end
    stop(vid);
    pause;
    stoppreview(vid);
    closepreview(vid);
end


