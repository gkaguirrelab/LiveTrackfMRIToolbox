function [Report] = LiveTrack_GetReportVideo (TTLtrigger,GetRawVideo,recTime,savePath,saveName)
% This function replicates a standard driver to do pupil tracking during fMRI
% scans using a CRS LiveTrackAV unit. It will record an MPEG-4 video (10 fps)
% and produce a MAT report with raw tracking values of the pupil.
% There is also the option to record a RAW video using a USB video capture device
% that has the IR-camera stream fed as a RCA input, using ezcap
% VideoCapture tool (for mac).

% If TTLtrigger=true, the report
% collection is initialized by the user. The video recording is triggered
% by the first TR via a TTL input. Every TTL is recorded in the report
% file. Video and data collection will end 2 seconds later than the
% recording time set by the user.

% If TTLtrigger=false, the user will provide a trigger to start video and
% report acquisition. If TTL pulses are received, the report will show them.
%
% If GetRawVideo = true, the routine will also save a raw video via ezCap
% videoGrabber (must be installed and open).
%
% The recording will last recTime in seconds. Result files will be saved in
% savepath. It's possible to interrupt the recording prematurely pressing
% OK on the STOP NOW window. All data will be saved as they are at the
% moment the recording was aborted.
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
% - run this function.
%
% Usage example
%
% TTLtrigger= false;
% GetRawVideo= true;
% recTime= 15;
% savePath = ('/Users/giulia/Desktop/');
% [Report] = LiveTrack_GetReportVideo (TTLtrigger,GetRawVideo,recTime,savePath)
%
%
% June 2016 - Giulia Frazzetta: written and commented.
% July 21, 2016 - GF: added raw video collection option.
% July 29, 2016 - GF: added option to customize saved files names.
% August, 4, 2016 - GF: changed function name from LiveTrack_GetDataVideo
% to LiveTrack_GetReportVideo

%% demo mode
% set savepath
if ~exist ('TTLtrigger', 'var')
    TTLtrigger= false;
end
if ~exist ('GetRawVideo', 'var')
    GetRawVideo= false;
end
if ~exist ('recTime', 'var')
    recTime= 15;
end
if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop/');
end

%% set saving path and names
if ~exist ('saveName', 'var')
    formatOut = 'mmddyy_HHMMSS';
    timestamp = datestr((datetime('now')),formatOut);
    vidName = fullfile(savePath,['LiveTrackVIDEO_' timestamp]);
    reportName = fullfile(savePath,['LiveTrackREPORT_' timestamp '.mat']);
    RawVidName = ['RawVideo_' timestamp];
else
    vidName = fullfile(savePath,[saveName '_track']);
    reportName = fullfile(savePath,[saveName '_report.mat']);
    RawVidName = [saveName '_raw'];
end

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
fps =  1 / mean( diff( t ) ) % Verify that FPS is indeed 10

% set disk logging
vid.FramesPerTrigger = Inf;
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(vidName, 'MPEG-4');
diskLogger.FrameRate = fps * 2;  % Note that the default livetrack video fps is 10, but each frame is displayed twice. Hence, the livetrack video shows one in every 3 frames on the report.
diskLogger.Quality = 100;
vid.DiskLogger = diskLogger;
triggerconfig(vid, 'manual')

postBufferTime = 5; % 5 seconds


% get path for the Raw video recording Applescript
if GetRawVideo
    rawScriptPath = which('RawVideoRec.scpt');
end
    

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
    firstTTL = true;  %to detect first TTL
    log = true;
    TimerFlag = false;
    FS = stoploop('Interrupt data collection NOW');
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
    log = true;
    while (~FS.Stop() && log)
        % Wait for first TTL
        PsychHID('ReceiveReports', deviceNumber);
        [reports]=PsychHID('GiveMeReports', deviceNumber);
        buffer = [buffer reports];
        R = HID2struct(buffer);
        Report = R;
        R = 0;
        [reports] = [0];
        
        % Detect first TTL
        if firstTTL && Report(end).Digital_IO1 == 1
            if GetRawVideo
                RawTiming.scriptStarts = GetSecs;
                system(sprintf(['osascript ' rawScriptPath ' %s %s %s'], savePath, RawVidName, num2str(recTime+postBufferTime)));
                RawTiming.scriptEnds = GetSecs;
                % note that the video recording begins in the timeframe
                % between the 2 getsecs. This limits the raw video syncing
                % problem to the Frames with a Report.PsychHIDTime within
                % this interval.
            end
            trigger(vid);
            firstTTL = false;
            fprintf('\n TTL detected! \n');
            
            % Start timer
            TimerFlag = true;
            fprintf('\n LiveTrack: recording...\n');
        end
        
        % Record video and data after first TTL
        if TimerFlag == true
            tic
            while (~FS.Stop() && toc < recTime + postBufferTime) % We record some extra seconds here.
                PsychHID('ReceiveReports', deviceNumber);
                [reports]=PsychHID('GiveMeReports', deviceNumber);
                buffer = [buffer reports];
                R = HID2struct(buffer);
                Report = R;
                R = 0;
                [reports] = [0];
            end
            fprintf('\n LiveTrack:stopping...\n');
            toc % Elapsed time is displayed
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
    if GetRawVideo
        save(fullfile(savePath,[RawVidName '_timingInfo']), 'RawTiming');
    end
    fprintf('Matfile and video saved.\n');

else  %manual trigger
    % initialize
    fprintf('\n Press spacebar to initialize LiveTrack.');
    pause;
    [reports] = [0];
    PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
    
    % set starting flags
    log = true; %logging
    firstTTL = true;
    
    %initialize video ob
    start(vid); 
    
    % Play a sound
    t = linspace(0, 1, 10000);
    y = sin(440*2*pi*t);
    sound(y, 20000);
    
    
    fprintf('\n Press spacebar to start collecting video and data.');
    pause;
    fprintf('\n LiveTrack: recording...\n');
    LiveTrackHIDcomm(deviceNumber,'begin');
    if GetRawVideo
        RawTiming.scriptStarts = GetSecs;
        system(sprintf(['osascript ' rawScriptPath ' %s %s %s'], savePath, RawVidName, num2str(recTime+postBufferTime)));
        RawTiming.scriptEnds = GetSecs;
        % note that the video recording begins in the timeframe
        % between the 2 getsecs. This limits the raw video syncing
        % problem to the Frames with a Report.PsychHIDTime within
        % this interval.
    end
    RawTiming.trackVidTriggerStarts = GetSecs;
    trigger(vid);
    RawTiming.trackVidTriggerEnds = GetSecs;
    FS = stoploop('Interrupt data collection NOW');
    tic
    % Preallocate the buffer
    buffer = [];
    while  log
        while (~FS.Stop() && toc < recTime + postBufferTime) % We record some extra seconds here.
            PsychHID('ReceiveReports', deviceNumber);
            [reports]=PsychHID('GiveMeReports', deviceNumber);
            buffer = [buffer reports];
            R = HID2struct(buffer);
            Report = R;
            R = 0;
            [reports] = [0];
            % check if a TTL pulse is received within the first 30 seconds
            if firstTTL && toc < 30
                if Report(end).Digital_IO1 == 1
                    fprintf('\n >> First TTL received!')
                    firstTTL = false;
                end
            else
                firstTTL = false;
            end     
        end
        fprintf('\nLiveTrack:stopping...\n');
        toc % Elapsed time is displayed
        log = false;
    end
    % stop video e data recording
    LiveTrackHIDcomm(deviceNumber,'end');
    pause(0.5);
    stop(vid);
    stoppreview(vid);
    closepreview(vid);
    save(reportName, 'Report');
    if GetRawVideo
        save(fullfile(savePath,[RawVidName '_timingInfo']), 'RawTiming');
    end
    fprintf('Matfile and video saved.\n');
end

% Clean the video object
delete(vid)
close(gcf)

FS.Clear() ;
clear FS ;


