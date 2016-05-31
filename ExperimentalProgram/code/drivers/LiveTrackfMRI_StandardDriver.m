function params = LiveTrackfMRI_StandardDriver(expt)
% This function is is our standard drive to do pupil tracking during fMRI
% scans using a CRS LiveTrackAV unit. It will record an AVI video (10 fps)
% and produce a MAT report with tracking values of the pupil. The report collection is initialized by the user. The video
% recording is triggered by the first TR via a TTL input. Every TTL is
% recorded in the report file. Video and data collection will end 5 seconds
% later than the recording time set by the user.

% HOW TO USE:
% At the beginning of the session:
% - make sure that the LiveTrackAV focusing screw has enough grip on the
% thread.
% - position the LiveTrackAV on the head mount.
% - focus the lens on the subject pupil.
% - verify the tracking on the preview window (it can be selected from
% LiveTrackfMRI_RunExp.
% - run this function.
% - select the appropriate recording time in seconds
% - initiate the LiveTrackAV

% May 2016 - Giulia Frazzetta, Manuel Spitschan: written.

%% Set variables
% Pre allocate params
params = [];

%set video file name
vidName = fullfile(expt.subjectDataDir, [expt.obsIDAndRun '.avi']);

% find  LivetrackAV for data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

% find  LivetrackAV for video recording
vid = videoinput('macvideo', 1, 'YUY2_320x240');
src = getselectedsource(vid);

%% Data and video collection initialization
% prompt user to initialize LiveTrackAV
fprintf('\n Press spacebar to initialize LiveTrack.');
pause;

% video recording settings
vid.FramesPerTrigger = Inf;
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(vidName, 'Motion JPEG AVI');
diskLogger.FrameRate = 10;  % Note that this is the default LiveTrack Camera interface frameRate.
diskLogger.Quality = 75;
vid.DiskLogger = diskLogger;
triggerconfig(vid, 'manual')

% clear reports variable
[reports] = [0];

% reset the framecount
PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));

% initiate data collection
LiveTrackHIDcomm(deviceNumber,'begin');

% initiate video object
start(vid);

% set starting flags
firstTTL = true;
log = true;
TimerFlag = false;

% notify listening mode (the camera is waiting for a TTL input)
fprintf('\n LiveTrack: Listening...');

% Play a sound
t = linspace(0, 1, 10000);
y = sin(440*2*pi*t);
sound(y, 20000);

%% Data and video collection
% preallocate the buffer
buffer = [];
% record video and data
while log
    % wait for first TTL
    PsychHID('ReceiveReports',deviceNumber);
    [reports]=PsychHID('GiveMeReports',deviceNumber);
    buffer = [buffer reports];
    R = HID2struct(buffer);
    Report = R;
    R = 0;
    [reports] = [0];
    
    % detect first TTL
    if Report(end).Digital_IO1 == 1 && firstTTL
        trigger(vid);
        firstTTL = false;
        fprintf('\n TTL detected! \n');
        
        %start timer
        TimerFlag = true;
        fprintf('\n LiveTrack: recording...');
    end
    
    % record video after first TTL
    if TimerFlag == true
        tic
        while toc < expt.recTimeInSecs + 5 %we record some extra seconds here.
            pause(1);
            toc % elapsed time is displayed
            PsychHID('ReceiveReports',deviceNumber);
            [reports]=PsychHID('GiveMeReports',deviceNumber);
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
% stop video e data recording
LiveTrackHIDcomm(deviceNumber,'end');
pause(0.5);
stop(vid);

% save report
params.Report = Report;

% clean the video object
delete(vid)
close(gcf)
