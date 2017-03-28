function R = HID2struct(reports)
% HID2struct transforms report packets with raw data into a structure
% array, that can be saved as a mat file. Note that the camera is a dual
% channel device. Each channel samples at 30Hz. The 2 channels input are
% acquired one after the other in each frame, so that considering Ch01 and
% Ch02 outputs for each frame returns a 60Hz sampling rate. This means that
% for every frame (i.e. every entry on the report file), there are 2
% complete datasets one for each of the 2 samples recorded in that frame.

% For each FRAME, these data are collected:
% - PsychHIDTime : PsychHID time stamp of when the report was received
% - FrameCount : corresponds to the frame count on the video
% - Digital_IO : it's the trigger input; can be either 0 or 1 (when a TTL is received)

% For each CHANNEL (i.e. 2 per frame), these data are collected:
% - PupilWidth : width of the pupil in this sample (will be zero if not tracked)
% - PupilHeight : height of the pupil in this sample (will be zero if not tracked)
% - PupilCameraX : X camera coordinate of the pupil in this sample
% - PupilCameraY : Y camera coordinate of the pupil in this sample
% - Glint1CameraX : X camera coordinate of the glint 1 in this sample
% - Glint1CameraY : Y camera coordinate of the glinti 2 in this sample
% - Glint2CameraX : X camera coordinate of the glint 2 in this sample (if
% any)
% - Glint2CameraY : Y camera coordinate of the glint 2 in this sample (if
% any)



% This function was written following the section 'Using the HID interface'
% on the LiveTrack User Manual (p.23 and on).



% May 2016 - written, Giulia Frazzetta

%% Check if there are reports
if isempty(reports)
    fprintf('No reports found\n');
    R = [];
    return
end


noOfReports = 1;

%% Pre allocate .mat file fields
% here we pre allocate the field of the report that we obtain as an output
% for data collection. By default, both channel's data is saved out, the
% user can later decide whether to use single (30Hz) or dual (60Hz) channel
% data for the analysis.

if isstruct(reports), % input is a structure (return from giveMeReports)
    
    noOfReports = length(reports);
    
    % PsychHID Time
    R(length(reports)).PsychHIDtime = 0;
    
    % frameCount
    R(length(reports)).frameCount = 0;
    
    % pupil tracked flag
    R(length(reports)).PupilTracked_Ch01 = 0;
    R(length(reports)).PupilTracked_Ch02 = 0;
    
    % TTL received flag
    R(length(reports)).Digital_IO1 = 0;
    R(length(reports)).Digital_IO2 = 0;
    
    % data from channel 01 (first sample)
    R(length(reports)).PupilWidth_Ch01 = 0;
    R(length(reports)).PupilHeight_Ch01 = 0;
    R(length(reports)).PupilCameraX_Ch01 = 0;
    R(length(reports)).PupilCameraY_Ch01 = 0;
    R(length(reports)).Glint1CameraX_Ch01 = 0;
    R(length(reports)).Glint1CameraY_Ch01 = 0;
    R(length(reports)).Glint2CameraX_Ch01 = 0;
    R(length(reports)).Glint2CameraY_Ch01 = 0;
    
    % data from channel 02 (second sample)
    R(length(reports)).PupilWidth_Ch02 = 0;
    R(length(reports)).PupilHeight_Ch02 = 0;
    R(length(reports)).PupilCameraX_Ch02 = 0;
    R(length(reports)).PupilCameraY_Ch02 = 0;
    R(length(reports)).Glint1CameraX_Ch02 = 0;
    R(length(reports)).Glint1CameraY_Ch02 = 0;
    R(length(reports)).Glint2CameraX_Ch02 = 0;
    R(length(reports)).Glint2CameraY_Ch02 = 0;
    
    
end

%% Populate the report
for k=1:noOfReports,
    if isstruct(reports),
        R(k).PsychHIDtime = reports(k).time;
        r = double(reports(k).report);
    else
        r = double(reports);
    end
    
    % check flag
    Ch01_Flag = dec2bin(r(17)+r(18)*256,16);
    if strcmp(Ch01_Flag(11:12),'01'), % set to look for 1 glint (LiveTrack AV)
        R(k).PupilTracked_Ch01 = strcmp(Ch01_Flag(13:16),'0111');
    elseif strcmp(Ch01_Flag(11:12),'10'), % set to look for 2 glints (LiveTrack FM)
        R(k).PupilTracked_Ch01 = strcmp(Ch01_Flag(13:16),'1111');
    else
        if strcmp(Ch01_Flag(16),'1'), % tracking is enabled
            error('looking for an undefined amount of glints!');
        else
            R(k).PupilTracked_Ch01 = false;
        end
    end
    Ch02_Flag = dec2bin(r(41)+r(42)*256,16);
    if strcmp(Ch02_Flag(11:12),'01'), % set to look for 1 glint (LiveTrack AV)
        R(k).PupilTracked_Ch02 = strcmp(Ch02_Flag(13:16),'0111');
    elseif strcmp(Ch02_Flag(11:12),'10'), % set to look for 2 glints (LiveTrack FM)
        R(k).PupilTracked_Ch02 = strcmp(Ch02_Flag(13:16),'1111');
    else
        if strcmp(Ch02_Flag(16),'1'), % tracking is enabled
            error('looking for an undefined amount of glints!');
        else
            R(k).PupilTracked_Ch02 = false;
        end
    end
    
    % decode the frame count
    R(k).frameCount = r(9)+r(10)*256+r(11)*256^2+r(12)*256^3+r(13)*256^4+r(14)*256^5+r(15)*256^6+r(16)*256^7;
    
    % Scaling factors: the 'units' of the values on the report are scaled by
    % this factor. Therefore, we divide them by these factors to show the
    % actual units on the report. (ref. User Manual pag.30)
    % Channel01 scaling factor
    Ch01_ScalingFactor = r(23)+r(24)*256;
    % Channel02 scaling factor
    Ch02_ScalingFactor = r(47)+r(48)*256;
    
    % Assign parameters
    R(k).Digital_IO1 = r(5);
    R(k).Digital_IO2 = r(6);
    
    % channel 01 parameters, scaled by Ch01_ScalingFactor
    R(k).PupilWidth_Ch01 = (r(25)+r(26)*256)/Ch01_ScalingFactor;
    R(k).PupilHeight_Ch01 = (r(27)+r(28)*256)/Ch01_ScalingFactor;
    R(k).PupilCameraX_Ch01 = (r(29)+r(30)*256)/Ch01_ScalingFactor;
    R(k).PupilCameraY_Ch01 = (r(31)+r(32)*256)/Ch01_ScalingFactor;
    R(k).Glint1CameraX_Ch01 = (r(33)+r(34)*256)/Ch01_ScalingFactor;
    R(k).Glint1CameraY_Ch01 = (r(35)+r(36)*256)/Ch01_ScalingFactor;
    R(k).Glint2CameraX_Ch01 = (r(37)+r(38)*256)/Ch01_ScalingFactor;
    R(k).Glint2CameraY_Ch01 = (r(39)+r(40)*256)/Ch01_ScalingFactor;
    
    % channel 02 parameters, scaled by Ch02_ScalingFactor
    R(k).PupilWidth_Ch02 = (r(49)+r(50)*256)/Ch02_ScalingFactor;
    R(k).PupilHeight_Ch02 = (r(51)+r(52)*256)/Ch02_ScalingFactor;
    R(k).PupilCameraX_Ch02 = (r(53)+r(54)*256)/Ch02_ScalingFactor;
    R(k).PupilCameraY_Ch02 = (r(55)+r(56)*256)/Ch02_ScalingFactor;
    R(k).Glint1CameraX_Ch02 = (r(57)+r(58)*256)/Ch02_ScalingFactor;
    R(k).Glint1CameraY_Ch02 = (r(59)+r(60)*256)/Ch02_ScalingFactor;
    R(k).Glint2CameraX_Ch02 = (r(61)+r(62)*256)/Ch02_ScalingFactor;
    R(k).Glint2CameraY_Ch02 = (r(63)+r(64)*256)/Ch02_ScalingFactor;
end

