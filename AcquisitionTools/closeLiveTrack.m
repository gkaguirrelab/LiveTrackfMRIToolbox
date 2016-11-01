function closeLiveTrack

% Function to safely stop the LiveTrack device. Using this before/instead
% of "clear all" should prevent PsychHID-related matlab crashes.


%% find LiveTrack
deviceList = PsychHID('Devices');
productNames = arrayfun(@(x)x.product, deviceList,'UniformOutput',0);
productName = strfind(productNames, 'LiveTrack');
deviceNumber = find(not(cellfun('isempty', productName)));
%% start and then stop livetrack
% low level command to start raw tracking (in camera pixel units) and return results (ref Livetrack user manual p.25)
PsychHID('SetReport', deviceNumber, 2, 0, uint8([104 zeros(1,63)]));
PsychHID('ReceiveReports', deviceNumber);
[reports] = PsychHID('GiveMeReports', deviceNumber);
PsychHID('ReceiveReportsStop',deviceNumber);
% low level command to stop raw tracking (in camera pixel units) and return results (ref Livetrack user manual p.25)
PsychHID('SetReport', deviceNumber, 2, 0, uint8([102 zeros(1,63)]));