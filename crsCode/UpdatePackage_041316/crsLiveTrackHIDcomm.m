function R = crsLiveTrackHIDcomm(deviceNumber,mode)
% This function handles the data acquisition for LiveTrack by using the
% Psychtoolbox PsychHID function.
%
% deviceNumber must be the number of the LiveTrack device. You can find it
% with the LiveTrackHIDGetDeviceNumber function.
%
% Mode must be either 'begin', 'begin-cal', 'continue',
% 'continue-returnlast', 'continue-returnnext', 'return all' or 'end'.
%
% 'begin' tells LiveTrack to start sending raw data packets
%
% 'begin-cal' tells LiveTrack to start sending calibrated data packets
%
% 'continue' reads and empties the data packets from the HID buffer. The
% packets are added to a MATLAB variable containing packets from previous
% calls to 'continue'. 
%
% 'continue-returnlast' does the same as 'continue' but also returns the 
% newest data packet.
%
% 'continue-returnnext' does the same as 'continue' but also returns the 
% next data packet. NB. Is will wait until the next packet arrives.
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
    % tell LiveTrack to start sending raw data packets
    SetReport([104 zeros(1,63)],deviceNumber);
    disp('LiveTrack: Started sending raw data.');
    % read and empty the data packets from the HID buffer (small - 9 
    % packets max?) and store them in the larger PsychHID buffer (default
    % size = 10000 reports)
    ReceiveReports(deviceNumber);
    R = [];
elseif strcmpi(mode,'begin-cal'),
    % tell LiveTrack to start sending calibrated data packets
    SetReport([105 zeros(1,63)],deviceNumber);
    disp('LiveTrack: Started sending calibrated data.');

    ReceiveReports(deviceNumber);
    R = [];
elseif  strcmpi(mode,'continue'),
    ReceiveReports(deviceNumber);
    
    % store the packets in the MATLAB variable
    reports = GiveMeReports(deviceNumber);
    
    buffer = [buffer reports];
    R = [];
elseif  strcmpi(mode,'continue-returnnext'),
    if isempty(buffer),
        lastReport.time = 0;
    else
        lastReport = buffer(end);
    end
    curReport = lastReport;
    while curReport.time==lastReport.time,
        crsLiveTrackHIDcomm(deviceNumber,'continue');
        if isempty(buffer),
            curReport.time = 0;
        else
            curReport = buffer(end);
        end
    end
    R = LiveTrackHID2struct(buffer(end));
elseif  strcmpi(mode,'continue-returnlast'),
    crsLiveTrackHIDcomm(deviceNumber,'continue');
    if isempty(buffer),
        R = [];
    else
        R = LiveTrackHID2struct(buffer(end));
    end
elseif  strcmpi(mode,'return all'),
    crsLiveTrackHIDcomm(deviceNumber,'continue');
    R = LiveTrackHID2struct(buffer);
    clear buffer
elseif  strcmpi(mode,'end'),
    % tell LiveTrack to stop sending data packets
    SetReport([102 zeros(1,63)],deviceNumber);
    disp('LiveTrack: Stopped sending raw data.');
    
    ReceiveReportsStop(deviceNumber);
    R = [];
else
   error('mode must be either "begin", "continue", "return all" or "end"');
end

function SetReport(report, deviceNumber)
    err = PsychHID('SetReport', deviceNumber, 2, 0, uint8(report));
    if err.n
        fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
end

function ReceiveReports(deviceNumber)
        err = PsychHID('ReceiveReports',deviceNumber);
    if err.n
        fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
end

function ReceiveReportsStop(deviceNumber)
        err = PsychHID('ReceiveReportsStop',deviceNumber);
    if err.n
        fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
end

function reports = GiveMeReports(deviceNumber)
    [reports,err]=PsychHID('GiveMeReports',deviceNumber);
    if err.n
        fprintf('\nPsychHID: GiveMeReports error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
    end
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

    S1FieldNamesCal = {'S1PupilW','S1PupilH','S1GazeX','S1GazeY','S1GazeZ','S1Azimuth',...
            'S1Elevation','S1Longitude','S1Latitude'};

    S2FieldNamesCal = {'S2PupilW','S2PupilH','S2GazeX','S2GazeY','S2GazeZ','S2Azimuth',...
            'S2Elevation','S2Longitude','S2Latitude'};

    noOfReports = 1;

    if isstruct(reports), % input is a structure (return from giveMeReports)
        noOfReports = length(reports);
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

        if r(1)==200, % if raw data
            % S1 scaling factor
            S1Scaling = r(23)+r(24)*256;
            % S2 scaling factor
            S2Scaling = r(47)+r(48)*256;
        elseif r(1)==201, % if calibrated data
            S1Scaling = 32;
            S2Scaling = 32;
        else
            error('neither raw or calibrated data')
        end

        r=uint16(r);

        if r(1)==200, % if raw data
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
        elseif r(1)==201,  % if calibrated data
            c=0;
            for i=23:2:39,
                c=c+1;
                R(k).(S1FieldNamesCal{c}) = double(typecast(r(i)+r(i+1)*256,'int16'))/S1Scaling;
            end

            c=0;
            for i=47:2:63,
                c=c+1;
                R(k).(S2FieldNamesCal{c}) = double(typecast(r(i)+r(i+1)*256,'int16'))/S2Scaling;
            end
        else
            error('neither raw or calibrated data')
        end
    end

end

end