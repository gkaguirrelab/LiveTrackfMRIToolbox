function [TTLreceived, TTLstartTime] = wait4TTL(waitTime)

%% Waits for a TTL signal from the scanner
%
%   Usage:
%       [TTLreceived, startTime]   = wait4TTL(waitTime);
%
%   Defaults:
%       waitTime    = 20; % seconds
%
%   Written by Andrew S Bock and Giulia Frazzetta Sep 2016

%% set defaults
if ~exist('waitTime','var')
    waitTime        = 20;
end
%% Get the LiveTrack device
deviceList = PsychHID('Devices');
productNames = arrayfun(@(x)x.product, deviceList,'UniformOutput',0);
productName = strfind(productNames, 'LiveTrack');
deviceNumber = find(not(cellfun('isempty', productName)));
PsychHID('SetReport', deviceNumber, 2, 0, uint8([104 zeros(1,63)]));
%% Wait for TTL pulse
commandwindow;
disp('Waiting for TTL pulse...');
endScript = 0;
TTLstartTime = GetSecs;
elapsedTime = 0;
TTLreceived = 0;
while elapsedTime < waitTime && ~endScript
    elapsedTime = GetSecs - TTLstartTime;
    PsychHID('ReceiveReports', deviceNumber);
    [reports] = PsychHID('GiveMeReports', deviceNumber);
    if size(reports,2) ~=0
        tmp                 = reports.report;
        r                   = double(tmp);
        % Check if 't' is in report
        if r(5) == 1
            disp('TTL received');
            TTLstartTime       = reports.time;
            PsychHID('ReceiveReportsStop',deviceNumber);
            PsychHID('SetReport', deviceNumber, 2, 0, uint8([102 zeros(1,63)]));
            TTLreceived = 1;
            endScript = 1;
        end
    end
    PsychHID('ReceiveReportsStop',deviceNumber);
    pause(0.001);
end
if ~endScript
    disp('timeout - TTL NOT received');
    PsychHID('SetReport', deviceNumber, 2, 0, uint8([102 zeros(1,63)]));
end
closeLiveTrack