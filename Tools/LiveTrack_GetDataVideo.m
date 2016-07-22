function [Report] = LiveTrack_GetDataVideo (TTLtrigger,GetRawVideo,recTime,savePath)
% This function replicates a standard protocol to do pupil tracking during fMRI
% scans using a CRS LiveTrackAV unit. It will record an MPEG-4 video (10 fps)
% and produce a MAT report with raw tracking values of the pupil.

% If TTLtrigger=true, the report
% collection is initialized by the user. The video recording is triggered
% by the first TR via a TTL input. Every TTL is recorded in the report
% file. Video and data collection will end 2 seconds later than the
% recording time set by the user.

% If TTLtrigger=false, the user will provide a trigger to start video and
% data acquisition simultaneously. The report will show no TTL or
% keypresses.
%
% The recording will last recTime in seconds. Results file will be saved in
% savepath.
%
% It is possible to run this function in demo mode, with manual trigger and
% a recording of 15 seconds saved on the desktop.


% HOW TO USE:
% At the beginning of the session:
% - make sure that the LiveTrack focusing screw has enough grip on the
% thread. Scanner vibrations could unscrew the lens causing a loss of
% focus.
% - position the LiveTrack on the head mount.
% - focus the lens on the subject pupil.
% - verify the tracking on the preview window.
% - run this function
%
% Usage example
%
% TTLtrigger= false;
% GetRawVideo= true;
% recTime= 15;
% savePath = ('/Users/giulia/Desktop/');
% [Report] = LiveTrack_GetDataVideo (TTLtrigger,GetRawVideo,recTime,savePath)
%
%
% June 2016 - Giulia Frazzetta: written.
% July 21, 2016 - GF: added raw video collection option

%% demo mode
% set savepath
if ~exist ('TTLtrigger', 'var')
    TTLtrigger= false;
end
if ~exist ('GetRawVideo', 'var')
    GetRawVideo= true;
end
if ~exist ('recTime', 'var')
    recTime= 15;
end
if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop');
end


%% set saving path and names
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
vidName = fullfile(savePath,['LiveTrackVIDEO_' timestamp]);
reportName = fullfile(savePath,['LiveTrackREPORT_' timestamp '.mat']);
RawVidName = ['RawVideo_' timestamp];

%% Set Livetrack
% data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

% video recording settings
vid = videoinput('macvideo', 1, 'YUY2_320x240');
src = getselectedsource(vid);

% evaluate framerate
vid.FramesPerTrigger = 30;
start( vid );
wait( vid, Inf );
[d t] = getdata( vid, vid.FramesAvailable );
fps =  1 / mean( diff( t ) )

% set disk logging
vid.FramesPerTrigger = Inf;
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(vidName, 'MPEG-4');
diskLogger.FrameRate = fps * 2;  % Note that the default livetrack fps is 10
diskLogger.Quality = 100;
vid.DiskLogger = diskLogger;
triggerconfig(vid, 'manual')

postBufferTime = 5; % 5 seconds

%% record video and data
if TTLtrigger
    % Prompt user to initialize LiveTrackAV
    fprintf('\n Press spacebar to initialize LiveTrack.');
    pause;
    
    % Clear reports variable
    [reports] = [0];
    
    % Reset the framecount
    PsychHID('SetReport', deviceNumber, 2, 0, uint8([103 zeros(1,63)]));
    
    % Initiate data collection
    LiveTrackHIDcomm(deviceNumber, 'begin');
    
    % Initiate video object
    start(vid);
    
    % Set starting flags
    firstTTL = true;
    log = true;
    TimerFlag = false;
    
    % Notify listening mode (the camera is waiting for a TTL input)
    fprintf('\n LiveTrack: Listening...');
    
    % Play a sound
    t = linspace(0, 1, 10000);
    y = sin(440*2*pi*t);
    sound(y, 20000);
    
    % Data and video collection
    % Preallocate the buffer
    buffer = [];
    % Record video and data
    while log
        % Wait for first TTL
        PsychHID('ReceiveReports', deviceNumber);
        [reports]=PsychHID('GiveMeReports', deviceNumber);
        buffer = [buffer reports];
        R = HID2struct(buffer);
        Report = R;
        R = 0;
        [reports] = [0];
        
        % Detect first TTL
        if Report(end).Digital_IO1 == 1 && firstTTL
            if GetRawVideo
                system(sprintf('osascript /Users/Shared/Matlab/gkaguirrelab/LiveTrackfMRIToolbox/Tools/RawVideoRec.scpt %s %s %s', savePath, RawVidName, num2str(recTime+postBufferTime)));
            end
            trigger(vid);
            firstTTL = false;
            fprintf('\n TTL detected! \n');
            
            % Start timer
            TimerFlag = true;
            fprintf('\n LiveTrack: recording...');
        end
        
        % Record video and data after first TTL
        if TimerFlag == true
            tic
            while toc < recTime + postBufferTime % We record some extra seconds here.
                pause(1);
                toc % Elapsed time is displayed
                PsychHID('ReceiveReports', deviceNumber);
                [reports]=PsychHID('GiveMeReports', deviceNumber);
                buffer = [buffer reports];
                R = HID2struct(buffer);
                Report = R;
                R = 0;
                [reports] = [0];
            end
            display('LiveTrack:stopping...');
            log = false;
        end
    end
    % Stop video and data recording
    LiveTrackHIDcomm(deviceNumber, 'end');
    pause(0.5);
    stop(vid);
    stoppreview(vid);
    closepreview(vid);
    save(reportName, 'Report');
    fprintf('Matfile and video saved.\n');
    
else
    % initialize
    fprintf('\n Press spacebar to initialize LiveTrack.');
    pause;
    [reports] = [0];
    PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
    LiveTrackHIDcomm(deviceNumber,'begin');
    start(vid); %initialize video ob
    
    % Play a sound
    t = linspace(0, 1, 10000);
    y = sin(440*2*pi*t);
    sound(y, 20000);
    
    fprintf('\n Press spacebar to start collecting video and data.');
    pause;
    if GetRawVideo
        system(sprintf('osascript /Users/Shared/Matlab/gkaguirrelab/LiveTrackfMRIToolbox/Tools/RawVideoRec.scpt %s %s %s', savePath, RawVidName, num2str(recTime+postBufferTime)));
    end
    trigger(vid);
    log = true;
    tic
    % Preallocate the buffer
    buffer = [];
    while log
        while toc < recTime + postBufferTime % We record some extra seconds here.
            pause(1);
            toc % Elapsed time is displayed
            PsychHID('ReceiveReports', deviceNumber);
            [reports]=PsychHID('GiveMeReports', deviceNumber);
            buffer = [buffer reports];
            R = HID2struct(buffer);
            Report = R;
            R = 0;
            [reports] = [0];
        end
        display('LiveTrack:stopping...');
        log = false;
    end
    % stop video e data recording
    LiveTrackHIDcomm(deviceNumber,'end');
    pause(0.5);
    stop(vid);
    stoppreview(vid);
    closepreview(vid);
    save(reportName, 'Report');
    fprintf('Matfile and video saved.\n');
end

% Clean the video object
delete(vid)
close(gcf)


