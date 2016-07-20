%% Video 1 on memory, video 2 on disk


recTime= 150;

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
vid1.ReturnedColorspace = 'rgb';



% source 2
vid2 = videoinput('macvideo', 2, 'YCbCr422_1280x720');
src2 = getselectedsource(vid2);
vid2.ReturnedColorspace = 'rgb';


postBufferTime = 2;

%% evaluate framerates

% video 1
vid1.FramesPerTrigger = 10;
start( vid1 );
wait( vid1, Inf );
[d1 t1] = getdata( vid1, vid1.FramesAvailable );
fps1 =  1 / mean( diff( t1 ) )

% video 2
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
%% record
fprintf('\n Press spacebar to initialize VideoRecording.');

vid1.FramesPerTrigger = Inf;
triggerconfig(vid1, 'manual')

vid2.FramesPerTrigger = Inf;
triggerconfig(vid2, 'manual')

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
    stop([vid1 vid2]);
    
%% transfer video 1 to disk
fprintf ('\n Writing videos to disk...');
tic;
% video 1
diskLogger1 = VideoWriter(vidName1, 'MPEG-4');
diskLogger1.Quality = 10;

[data1 t1] = getdata(vid1, vid1.FramesAvailable);
fps1 =  1 / mean( diff( t1 ) )
fps1std = std(diff(t1))
diskLogger1.FrameRate = fps1;
open(diskLogger1);
numFrames1 = size(data1, 4);
for ii = 1:numFrames1
    writeVideo(diskLogger1, data1(:,:,:,ii));
end
close(diskLogger1);
fprintf('\n Done.')
toc


%% clean up
    
close all    
clear
%     delete(vid1);
%     delete(vid2);
    close (gcf)
