%% Video 1 on disc, video 2 by applescript

 
recTime= 20;

[~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop/TEST/');

    
%% set saving path and names
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);

RawVidName = ['RawVideo_' timestamp];
LiveTrackVidName = fullfile(savePath,['LiveTrackVideo_' timestamp]);


%% video recording settings



% source 1
vid1 = videoinput('macvideo',  1, 'YUY2_320x240');
src1 = getselectedsource(vid1);
vid1.ReturnedColorspace = 'rgb';


postBufferTime = 2;


% video 1
vid1.FramesPerTrigger = 30;
start( vid1 );
wait( vid1, Inf );
[d t1] = getdata( vid1, vid1.FramesAvailable );
fps1 =  1 / mean( diff( t1 ) )

vid1.FramesPerTrigger = Inf;
vid1.LoggingMode = 'disk';
diskLogger = VideoWriter(LiveTrackVidName, 'Motion JPEG AVI');
diskLogger.FrameRate = round(fps1)*2;  % Note that this is the default LiveTrack Camera interface frameRate.
diskLogger.Quality = 50;
vid1.DiskLogger = diskLogger;
triggerconfig(vid1, 'manual')
%% record
fprintf('\n Press spacebar to initialize VideoRecording.');


vid1.FramesPerTrigger = Inf;
triggerconfig(vid1, 'manual')

pause;
start(vid1);


    fprintf('\n Press spacebar to start collecting video and data.');
    pause;
  trigger(vid1);
    system(sprintf('osascript /Users/Shared/Matlab/gkaguirrelab/LiveTrackfMRIToolbox/Tools/RawVideoRec.scpt %s %s %s', savePath, RawVidName, num2str(recTime+postBufferTime)));
    
    tic
     while toc < recTime + postBufferTime 
        toc
        pause(1);
    end
    fprintf('\n Stopping...');
    tic;
    stop(vid1);
    toc
%%

%% clean up
    
close all    
clear
%     delete(vid1);
%     delete(vid2);
    close (gcf)
