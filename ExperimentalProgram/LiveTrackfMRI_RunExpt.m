function LiveTrackfMRI_RunExpt
% LiveTrackfMRI_RunExpt - Run an experiment with the LiveTrackfMRI_Toolbox

%% Get the name of the m-file we're running.
exp.mFileName = mfilename;
exp.baseDir = fileparts(which(exp.mFileName));

% Figure out the data directory path.  The data directory should be on the
% same level as the code directory.
i = strfind(exp.baseDir, '/code');
exp.dataDir = sprintf('%sdata', exp.baseDir(1:i));

% Dynamically add the program code to the path if it isn't already on it.
if isempty(strfind(path, exp.baseDir))
    fprintf('- Adding %s dynamically to the path...', exp.mFileName);
    addpath(RemoveSVNPaths(genpath(exp.baseDir)), '-end');
    fprintf('Done\n');
end
gitInfo.(sprintf('%sSVNInfo', exp.mFileName)) = GetGITInfo(exp.baseDir);

%% Standard read of configuration information
[exp.configFileDir,exp.configFileName,exp.protocolDataDir,exp.protocolList,exp.protocolIndex] = GetExperimentConfigInfo(exp.baseDir,exp.mFileName,exp.dataDir);

saveDropbox = GetWithDefault('>>> Save into Dropbox folder?', 1);
if saveDropbox
    dataPath = getpref('OneLight', 'dataPath');
    exp.protocolDataDir = fullfile(dataPath, exp.protocolList(exp.protocolIndex).dataDirectory);
end

%% Add the config suffix 'protocols' to the 'configFileDir' field of 'exp'.
exp.configFileDir = fullfile(exp.configFileDir, 'protocols');

%% Set up data directory for this subject
[exp.subject,exp.subjectDataDir,exp.saveFileName] = OLGetSubjectDataDirMR(exp.protocolDataDir,exp.protocolList,exp.protocolIndex);
[~, exp.obsIDAndRun] = fileparts(exp.saveFileName);

%% Store the date/time when the experiment starts.
exp.experimentTimeNow = now;
exp.experimentTimeDateString = datestr(exp.experimentTimeNow);

%% Now we can execute the driver associated with this protocol.
driverCommand = sprintf('params = %s(exp);', exp.protocolList(exp.protocolIndex).driver);
eval(driverCommand);

%% Save the experimental data 'params' along with the experimental setup
% data 'exp' and the SVN info.
save(exp.saveFileName, 'params', 'exp', 'gitInfo');
fprintf('- Data saved to %s\n', exp.saveFileName);