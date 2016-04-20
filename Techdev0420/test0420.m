formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
reportName = ['REPORT_' timestamp '.mat'];

[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
pause;
R = LiveTrackHIDcomm(deviceNumber,'begin');
pause;
err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
pause;
R = LiveTrackHIDcomm(deviceNumber,'return all');
save((fullfile('/Users/giulia/Desktop/TEST/',reportName)), 'R');
LiveTrackHIDcomm(deviceNumber,'end');