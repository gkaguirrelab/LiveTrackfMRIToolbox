[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
pause;
R = LiveTrackHIDcomm(deviceNumber,'begin');
pause;
err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
pause;
R = LiveTrackHIDcomm(deviceNumber,'return all');
save('/Users/giulia/Desktop/TEST/REPORT.mat', 'R');
LiveTrackHIDcomm(deviceNumber,'end');