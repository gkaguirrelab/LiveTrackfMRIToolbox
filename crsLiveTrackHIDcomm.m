function R = crsLiveTrackHIDcomm(deviceNumber,mode)
% This function handles the data acquisition for LiveTrack by using the
% Psychtoolbox PsychHID function.
%
% deviceNumber must be the number of the LiveTrack device. You can find it
% with the LiveTrackHIDGetDeviceNumber function.
%
% mode must be either 'begin', 'continue', 'continue-returnlast', 'return all' or 'end'
%
% 'begin' tells LiveTrack to start sending data packets
%
% 'continue' reads and empties the data packets from the HID buffer. The
% packets are added to a MATLAB variable containing packets from previous
% calls to 'continue'. 
%
% 'continue-returnlast' does the same as 'continue' but also returns the 
% newest data packet.
%
% 'return all' does the same as 'continue' except all data packets from
% this and previous calls to 'continue' are returned and the MATLAB
% variable is emptied.
%
% 'end' tells LiveTrack to stop sending data packets.

persistent buffer

if nargin<2,
    error('You must select a device number and a operating mode for this function. See the help.');
end

if strcmpi(mode,'begin'),
    % tell LiveTrack to start sending data packets
    err = PsychHID('SetReport', deviceNumber, 2, 0, uint8([104 zeros(1,63)]));
    if err.n
        fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    else
        fprintf('\nLiveTrack: Started sending raw data.\n');
    end 
    
    % read and empty the data packets from the HID buffer (small) and store 
    % them in the larger PsychHID buffer (default size = 10000 reports)
    err = PsychHID('ReceiveReports',deviceNumber);
    if err.n
        fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
    R = [];
elseif  strcmpi(mode,'continue'),
    % read and empty the data packets from the HID buffer (small) and store 
    % them in the largeer PsychHID buffer (default size = 10000 reports)
    err = PsychHID('ReceiveReports',deviceNumber);
    if err.n
        fprintf('\nPsychHID: ReceiveReports error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
    [reports,err]=PsychHID('GiveMeReports',deviceNumber);
    if err.n
        fprintf('\nPsychHID: GiveMeReports error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
    buffer = [buffer reports];
    R = [];
elseif  strcmpi(mode,'continue-returnlast'),
    crsLiveTrackHIDcomm(deviceNumber,'continue');
    R = LiveTrackHID2struct(buffer(end));
elseif  strcmpi(mode,'return all'),
    crsLiveTrackHIDcomm(deviceNumber,'continue');
    R = LiveTrackHID2struct(buffer);
    clear buffer
elseif  strcmpi(mode,'end'),
    % tell LiveTrack to stop sending data packets
    err = PsychHID('SetReport', deviceNumber, 2, 0, uint8([102 zeros(1,63)]));
    if err.n
        fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    else
        fprintf('\nLiveTrack: Stopped sending raw data.\n');
    end
    
    err = PsychHID('ReceiveReportsStop',deviceNumber);
    if err.n
        fprintf('\nPsychHID: ReceiveReportsStop error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
    R = [];
else
   error('mode must be either "begin", "continue", "return all" or "end"');
end


function R = LiveTrackHID2struct(reports)
% LiveTrackHID2struct transforms report packets with raw data into a
% structure array. S1 is the first sample and S2 is the second.


if isempty(reports)
    fprintf('No reports found\n');
    R = [];
    return
end

S1FieldNames = {'S1PupilW','S1PupilH','S1PupilX','S1PupilY',...
        'S1Glint1X','S1Glint1Y','S1Glint2X','S1Glint2Y'};

S2FieldNames = {'S2PupilW','S2PupilH','S2PupilX','S2PupilY',...
        'S2Glint1X','S2Glint1Y','S2Glint2X','S2Glint2Y'};
    
noOfReports = 1;
    
if isstruct(reports), % input is a structure (return from giveMeReports)
    
    noOfReports = length(reports);
    
    % pre allocate
    R(length(reports)).PsychHIDtime = 0;
    R(length(reports)).S1Tracked = 0;
    R(length(reports)).S2Tracked = 0;
    R(length(reports)).timeStamp = 0;
    R(length(reports)).Digital_IO1 = 0;
    R(length(reports)).Digital_IO2 = 0;
    
    c=0;
    for i=25:2:39,
        c=c+1;
        R(length(reports)).(S1FieldNames{c}) = 0;
    end

    c=0;
    for i=49:2:63,
        c=c+1;
        R(length(reports)).(S2FieldNames{c}) = 0;
    end
end

% run through all reports
for k=1:noOfReports,
    if isstruct(reports),
        R(k).PsychHIDtime = reports(k).time;
        r = double(reports(k).report);
    else
        r = double(reports);
    end

    % check both flags
    S1Flag = dec2bin(r(17)+r(18)*256,16);
    if strcmp(S1Flag(11:12),'01'), % set to look for 1 glint (LiveTrack AV)
        R(k).S1Tracked = strcmp(S1Flag(13:16),'0111');
    elseif strcmp(S1Flag(11:12),'10'), % set to look for 2 glints (LiveTrack FM)
        R(k).S1Tracked = strcmp(S1Flag(13:16),'1111');
    else
        if strcmp(S1Flag(16),'1'), % tracking is enabled
            error('looking for an undefined amount of glints!');
        else
            R(k).S1Tracked = false;
        end
    end
    S2Flag = dec2bin(r(41)+r(42)*256,16);
    if strcmp(S2Flag(11:12),'01'), % set to look for 1 glint (LiveTrack AV)
        R(k).S2Tracked = strcmp(S2Flag(13:16),'0111');
    elseif strcmp(S2Flag(11:12),'10'), % set to look for 2 glints (LiveTrack FM)
        R(k).S2Tracked = strcmp(S2Flag(13:16),'1111');
    else
        if strcmp(S2Flag(16),'1'), % tracking is enabled
            error('looking for an undefined amount of glints!');
        else
            R(k).S2Tracked = false;
        end
    end
   
    % decode the timestamp
    R(k).timeStamp = r(9)+r(10)*256+r(11)*256^2+r(12)*256^3+r(13)*256^4+r(14)*256^5+r(15)*256^6+r(16)*256^7;


    % S1 scaling factor
    S1Scaling = r(23)+r(24)*256;

    % S2 scaling factor
    S2Scaling = r(47)+r(48)*256;

    r=uint16(r);

    c=0;
    for i=25:2:39,
        c=c+1;
        R(k).(S1FieldNames{c}) = double(typecast(r(i)+r(i+1)*256,'int16'))/S1Scaling;
    end

    c=0;
    for i=49:2:63,
        c=c+1;
        R(k).(S2FieldNames{c}) = double(typecast(r(i)+r(i+1)*256,'int16'))/S2Scaling;
    end
    
    % Assign digital IO
    R(k).Digital_IO1 = r(5);
    R(k).Digital_IO2 = r(6);
end

