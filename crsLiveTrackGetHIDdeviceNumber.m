function [deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber
% searches for a HID device with the product name 'LiveTrack'. Returns the
% one with the lowest device number if several is present as well as the
% prucuct name (e.g. LiveTrack-FM or LiveTrack-AV).

% get a list of all HID devices
deviceList = PsychHID('Devices');

% get cell array of product names for all HID devices
productNames = arrayfun(@(x)x.product, deviceList,'UniformOutput',0);

% find the one(s) with the name 'LiveTrack'
productName = strfind(productNames, 'LiveTrack'); 

% remove empty entries
deviceNumber = find(not(cellfun('isempty', productName)));

if isempty(deviceNumber),
    disp('No device named LiveTrack found!');
    return
end

% only return the first one if more is found
deviceNumber = deviceNumber(1); 

% try to find if type is 'FM' or 'AV'
type=productNames{deviceNumber};

%% alternative method

% deviceList = PsychHID('Devices');
% for i = 1:length(deviceList)
%     if strfind(deviceList(i).product, 'LiveTrack')
%         break
%     end
% end
% deviceNumber = i;