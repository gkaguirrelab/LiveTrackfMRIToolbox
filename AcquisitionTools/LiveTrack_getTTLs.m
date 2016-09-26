function [TTLs] = LiveTrack_getTTLs(recTime,savePath,saveName)
% Saves out a mini report displaying just the TTL fields and their
% corrisponding PsychHIDtime.


%% demo mode
if ~exist ('recTime', 'var')
    recTime= 15;
end
if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop/');
end
% set savename
if ~exist ('saveName', 'var')
    formatOut = 'mmddyy_HHMMSS';
    timestamp = datestr((datetime('now')),formatOut);
    reportName = fullfile(savePath,['LiveTrackTTL_' timestamp '.mat']);
else
    reportName = fullfile(savePath,[saveName '_TTL.mat']);
end

%% Connect to the LiveTrack
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

% set starting flags
log = true; %logging
fprintf('\n Press spacebar to start listening for TTLs.');
pause;
fprintf('\n LiveTrack: Listening...\n');
% start datastream
LiveTrackHIDcomm(deviceNumber,'begin');
% emergency stoploop tool
FS = stoploop('Interrupt data collection NOW');

tic
% Preallocate the buffer
buffer = [];
while  log
    while (~FS.Stop() && toc < recTime)
        PsychHID('ReceiveReports', deviceNumber);
        [reports]=PsychHID('GiveMeReports', deviceNumber);
        buffer = [buffer reports];
        R = TTL2struct(buffer);
        % check if a TTL pulse is received within the first 30 seconds
        if R(end).Digital_IO1 == 1
            fprintf('\n >> TTL received! ')
        end
        %transfer data to permanent variable (Report)
        TTLs = R;
        R = 0;
        [reports] = [0];
    end
    fprintf('\nLiveTrack:stopping...\n');
    toc % Elapsed time is displayed
    log = false;
end
% stop data stream
LiveTrackHIDcomm(deviceNumber,'end');
% save TTL variables
save(reportName, 'TTLs');

% clear stoploop object
FS.Clear() ;
clear FS ;