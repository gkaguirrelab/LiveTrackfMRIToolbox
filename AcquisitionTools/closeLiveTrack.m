function closeLiveTrack

% Function to safely stop the LiveTrack device. Using this before/instead
% of "clear all" prevents PsychHID-related matlab crashes.


%% find LiveTrack
deviceList = PsychHID('Devices');
productNames = arrayfun(@(x)x.product, deviceList,'UniformOutput',0);
productName = strfind(productNames, 'LiveTrack');
deviceNumber = find(not(cellfun('isempty', productName)));
%% start and the stop livetrack
PsychHID('SetReport', deviceNumber, 2, 0, uint8([104 zeros(1,63)]));
PsychHID('ReceiveReports', deviceNumber);
[reports] = PsychHID('GiveMeReports', deviceNumber);
PsychHID('ReceiveReportsStop',deviceNumber);
PsychHID('SetReport', deviceNumber, 2, 0, uint8([102 zeros(1,63)]));