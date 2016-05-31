function R = HID2struct(reports)
% HID2struct transforms report packets with raw data into a
% structure array.
% This function follows the section 'Using the HID interface' on the
% LiveTrack User Manual (p.23).


if isempty(reports)
    fprintf('No reports found\n');
    R = [];
    return
end

    
noOfReports = 1;
    
if isstruct(reports), % input is a structure (return from giveMeReports)
    
    noOfReports = length(reports);
    
    % pre allocate mat.file fields
    R(length(reports)).PsychHIDtime = 0;
    R(length(reports)).PupilTracked = 0;
    R(length(reports)).frameCount = 0;
    R(length(reports)).Digital_IO1 = 0;
    R(length(reports)).Digital_IO2 = 0;
    R(length(reports)).LeftPupilWidth = 0;
    R(length(reports)).LeftPupilHeight = 0;
    R(length(reports)).LeftPupilCameraX = 0;
    R(length(reports)).LeftPupilCameraY = 0;
    R(length(reports)).LeftGlint1CameraX = 0;
    R(length(reports)).LeftGlint1CameraY = 0;
    R(length(reports)).LeftGlint2CameraX = 0;
    R(length(reports)).LeftGlint2CameraY = 0;
    
    c=0;
  
end

% run through all reports
for k=1:noOfReports,
    if isstruct(reports),
        R(k).PsychHIDtime = reports(k).time;
        r = double(reports(k).report);
    else
        r = double(reports);
    end

    % check flag
    LeftFlag = dec2bin(r(17)+r(18)*256,16);
    if strcmp(LeftFlag(11:12),'01'), % set to look for 1 glint (LiveTrack AV)
        R(k).PupilTracked = strcmp(LeftFlag(13:16),'0111');
    elseif strcmp(LeftFlag(11:12),'10'), % set to look for 2 glints (LiveTrack FM)
        R(k).PupilTracked = strcmp(LeftFlag(13:16),'1111');
    else
        if strcmp(LeftFlag(16),'1'), % tracking is enabled
            error('looking for an undefined amount of glints!');
        else
            R(k).PupilTracked = false;
        end
    end

    % decode the timestamp
    R(k).frameCount = r(9)+r(10)*256+r(11)*256^2+r(12)*256^3+r(13)*256^4+r(14)*256^5+r(15)*256^6+r(16)*256^7;


    % Left camera scaling factor
    LeftCameraScaling = r(23)+r(24)*256;

%     r=uint16(r);
    
    % Assign parameters
    R(k).Digital_IO1 = r(5);
    R(k).Digital_IO2 = r(6);
    R(k).LeftPupilWidth = r(25)+r(26)*256;
    R(k).LeftPupilHeight = r(27)+r(28)*256;
    R(k).LeftPupilCameraX = r(29)+r(30)*256;
    R(k).LeftPupilCameraY = r(31)+r(32)*256;
    R(k).LeftGlint1CameraX = r(33)+r(34)*256;
    R(k).LeftGlint1CameraY = r(35)+r(36)*256;
    R(k).LeftGlint2CameraX = r(37)+r(38)*256;
    R(k).LeftGlint2CameraY = r(39)+r(40)*256;
end

