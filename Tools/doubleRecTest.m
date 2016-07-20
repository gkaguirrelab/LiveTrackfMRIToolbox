 recTime= 50;

[~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop');

    
%% set saving path and names
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);

vidName1 = fullfile(savePath,['VIDEO_01_' timestamp]);
vidName2 = fullfile(savePath,['VIDEO_02_' timestamp]);


%% video recording settings

% source 1
vid1 = videoinput('macvideo', 1, 'YUY2_1600x1200');
src1 = getselectedsource(vid1);

% Evaluate current framerate
vid1.FramesPerTrigger = 10;
start( vid1 );
wait( vid1, Inf );
[d1 t1] = getdata( vid1, vid1.FramesAvailable );
fps1 =  1 / mean( diff( t1 ) )

vid1.FramesPerTrigger = Inf;
vid1.LoggingMode = 'disk';
diskLogger1 = VideoWriter(vidName1, 'Motion JPEG AVI');
diskLogger1.FrameRate = round(fps1)*2; 
diskLogger1.Quality = 50;
vid1.DiskLogger = diskLogger1;
triggerconfig(vid1, 'manual')



% source 2
vid2 = videoinput('macvideo', 2, 'YCbCr422_1280x720');
src2 = getselectedsource(vid2);

% Evaluate current framerate
vid2.FramesPerTrigger = 10;
start( vid2 );
wait( vid2, Inf );
[d t2] = getdata( vid2, vid2.FramesAvailable );
fps2 =  1 / mean( diff( t2 ) )


vid2.FramesPerTrigger = Inf;
vid2.LoggingMode = 'disk';
diskLogger2 = VideoWriter(vidName2, 'Motion JPEG AVI');
diskLogger2.FrameRate = round(fps2)*2;  % Note that this is the default LiveTrack Camera interface frameRate.
diskLogger2.Quality = 50;
vid2.DiskLogger = diskLogger2;
triggerconfig(vid2, 'manual')

postBufferTime = 2;


%% record
    fprintf('\n Press spacebar to initialize VideoRecording.');
    pause;
start([vid1 vid2]);
% start(vid2);

    fprintf('\n Press spacebar to start collecting video and data.');
    pause;
    trigger([vid1 vid2]);
%     trigger(vid2);
    tic
     while toc < recTime + postBufferTime 
        toc
        pause(1);
    end
    fprintf('\n Stopping...');
    stop(vid2);
    clear ('vid2');
    stop (vid1)
close all    
clear
%     delete(vid1);
%     delete(vid2);
    close (gcf)

