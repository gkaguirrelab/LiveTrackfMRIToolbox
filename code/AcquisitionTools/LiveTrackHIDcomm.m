function R = LiveTrackHIDcomm(deviceNumber,mode)
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
    % them in the larger PsychHID buffer (default size = 10000 reports)
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
    LiveTrackHIDcomm(deviceNumber,'continue');
    R = HID2struct(buffer(end));
elseif  strcmpi(mode,'return all'),
    LiveTrackHIDcomm(deviceNumber,'continue');
    R = HID2struct(buffer);
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
   error('mode must be either "begin", "continue", "continue-returnlast", "return all" or "end"');
end
