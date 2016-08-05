function [Report] = LiveTrack_GetReportOnly (showTTL,recTime,savePath,saveName)
% Only saves out the report. The recording starts right away, no prompt is
% asked to the user. If showTTL is enabled, a message on the screen will
% notify the use that the first TTL was received; recTime will start after
% the TTL is received. Note that the first TTL does not trigger the report
% or video acquisition.
% If showTTL is off, no information about the first TTL is provided and
% recTime starts as soon as the report collection begins.

% Usage:
% showTTL = false;
% recTime = 15;
% savePath = fullfile('/Users/giulia/Desktop/');
% saveName = 'test'
% LiveTrack_GetReportOnly (showTTL,recTime,savePath,saveName)

% Aug 4 2016 - Giulia Frazzetta: written and commented.

%% demo mode
% set savepath
if ~exist ('TTLtrigger', 'var')
    showTTL= false;
end

if ~exist ('recTime', 'var')
    recTime= 15;
end
if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop/');
end

if ~exist ('saveName', 'var')
    formatOut = 'mmddyy_HHMMSS';
    timestamp = datestr((datetime('now')),formatOut);
    reportName = fullfile(savePath,['LiveTrackREPORT_' timestamp '.mat']);
else
    reportName = fullfile(savePath,[saveName '_report.mat']);
end

%% Set Livetrack
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

postBufferTime = 5; % 5 seconds

if showTTL
    
    % Clear reports variable
    [reports] = [0];
    
    % Reset the framecount
    PsychHID('SetReport', deviceNumber, 2, 0, uint8([103 zeros(1,63)]));
    
    % Initiate data collection
    LiveTrackHIDcomm(deviceNumber, 'begin');
    
    % Set starting flags
    firstTTL = true;
    TimerFlag = false;
    FS = stoploop('Interrupt data collection NOW');
    % Notify listening mode (the camera is waiting for a TTL input)
    fprintf('\n LiveTrack: Listening...');
    
    % Preallocate the buffer
    buffer = [];
    % Record video and data
    while ~FS.Stop()
        log = true;
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
                firstTTL = false;
                fprintf('\n TTL detected! \n');
                
                % Start timer
                TimerFlag = true;
            end
            
            % Record video and data after first TTL
            if TimerFlag == true
                tic
                while (~FS.Stop() && toc < recTime + postBufferTime) % We record some extra seconds here.
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
    end
    % Stop video and data recording
    LiveTrackHIDcomm(deviceNumber, 'end');
    pause(0.5);
    
    save(reportName, 'Report');
    fprintf('Report saved as %s.\n', reportName);
    
else
    
    [reports] = [0];
    PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
    LiveTrackHIDcomm(deviceNumber,'begin');
    
    log = true;
    FS = stoploop('Interrupt data collection NOW');
    tic
    % Preallocate the buffer
    buffer = [];
    while  log
        while (~FS.Stop() && toc < recTime + postBufferTime) % We record some extra seconds here.
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
    % stop data recording
    LiveTrackHIDcomm(deviceNumber,'end');
    pause(0.5);
    save(reportName, 'Report');
    fprintf('Report saved as %s.\n', reportName);
end


FS.Clear() ;
clear FS ;


