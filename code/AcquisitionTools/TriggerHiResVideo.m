function TimingInfo = TriggerHiResVideo(recTime, savePath, saveName)
% trigger raw video recording with first TTL from the LiveTrack
% device. 
% The function saves out the following TimingInfo calling GetSecs:
% - TTLtiming
% - Start and and Time of the applescript execution (i.e. script execution
% timeframe)


%% defaults and save names
if ~exist ('recTime', 'var')
    recTime= 15;
end
if ~exist ('savePath', 'var')
    [~, user_name] = system('whoami') ;
    savePath = fullfile('/Users', strtrim(user_name), '/Desktop');
end
% set saving path and names
if ~exist ('saveName', 'var')
    formatOut = 'mmddyy_HHMMSS';
    timestamp = datestr((datetime('now')),formatOut);
    reportName = fullfile(savePath,['TimingInfo_' timestamp '.mat']);
    RawVidName = ['Raw_' timestamp];
else
    reportName = fullfile(savePath,[saveName '_TimingInfo.mat']);
    RawVidName = [saveName '_raw'];
end

%% set path to applescript to start video recording with V.TOP device
% this step will be deleted when we get the new device.
rawScriptPath = which('RawVideoRec.scpt');

%% wait for TTL pulse and start recording
[TTLreceived, TimingInfo.TTLstartTime] = wait4TTL;
if TTLreceived
    % this part will be changed when we get the new device
    TimingInfo.scriptStarts = GetSecs;
    system(sprintf(['osascript ' rawScriptPath ' %s %s %s'], savePath, RawVidName, num2str(recTime)));
    TimingInfo.scriptEnds = GetSecs;
    save(reportName, 'TimingInfo');
else
    disp('Video recording did not start.')
end
