%data acquisition

%% Get device number
deviceList = PsychHID('Devices');
for i = 1:length(deviceList)
    if strfind(deviceList(i).product, 'LiveTrack')
        break
    end
end
deviceNumber = i;

%% Data acquisition
% start LiveTrack Raw data
crsLiveTrackHIDcomm(deviceNumber,'begin');

 R = crsLiveTrackHIDcomm(deviceNumber,'continue-returnlast')
 % calibrate the raw data
 Rcal = calibrateData(R,CalMat,Rpc,NoOfGlints);