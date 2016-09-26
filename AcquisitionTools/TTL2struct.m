function R = TTL2struct(reports)
% Based on HID2struc, just takes out the TTLs and the getsec value
% corrisponding when the information is received.

% Sept 2016 - written, Giulia Frazzetta

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

    
    % TTL received flag
    R(length(reports)).Digital_IO1 = 0;
    R(length(reports)).Digital_IO2 = 0;
    
end

%% Populate the report
for k=1:noOfReports,
    if isstruct(reports),
        R(k).PsychHIDtime = reports(k).time;
        r = double(reports(k).report);
    else
        r = double(reports);
    end
    
    % Assign TTL parameters
    R(k).Digital_IO1 = r(5);
    R(k).Digital_IO2 = r(6);
    
end

