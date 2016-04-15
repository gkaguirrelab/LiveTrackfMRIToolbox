%%
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;

%%
crsLiveTrackHIDcomm(deviceNumber,'begin')
pause;
R = crsLiveTrackHIDcomm(deviceNumber,'return all')
% pause;  
% [report, err] = PsychHID('GetReport', deviceNumber,1, 200, 64) 
% crsLiveTrackHIDcomm(deviceNumber,'end')
