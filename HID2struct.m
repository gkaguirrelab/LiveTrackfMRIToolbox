function R = HID2struct(reports)
% HID2struct transforms report packets with raw data into a
% structure array.

if isempty(reports)
    fprintf('No reports found\n');
    R = [];
    return
end

    
noOfReports = 1;
    
if isstruct(reports), % input is a structure (return from giveMeReports)
    
    noOfReports = length(reports);
    
    % pre allocate
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
%     for i=25:2:39,
%         c=c+1;
%         R(length(reports)).(FieldNames{c}) = 0;
%     end

   
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

    r=uint16(r);
    
    % Assign parameters
    R(k).Digital_IO1 = r(5);
    R(k).Digital_IO2 = r(6);
    R(k).LeftPupilWidth = r(25);
    R(k).LeftPupilHeight = r(27);
    R(k).LeftPupilCameraX = r(29);
    R(k).LeftPupilCameraY = r(31);
    R(k).LeftGlint1CameraX = r(33);
    R(k).LeftGlint1CameraY = r(35);
    R(k).LeftGlint2CameraX = r(37);
    R(k).LeftGlint2CameraY = r(39);
end

