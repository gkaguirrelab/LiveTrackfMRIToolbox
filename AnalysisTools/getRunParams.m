function [runParams] = getRunParams (params, dropboxDir)
% header

%% look for scale cal in each date (there is only one Scale calibration file per session)
ScaleCal = dir(fullfile(dropboxDir, params.projectFolder, params.projectSubfolder, ...
    params.subjectName,params.sessionDate,params.eyeTrackingDir,'*ScaleCal*.mat'));

%% look for Gaze Calibration files
GazeCals = dir(fullfile(dropboxDir, params.projectFolder, params.projectSubfolder, ...
    params.subjectName,params.sessionDate,params.eyeTrackingDir,'*LTcal*.mat'));


%% Create the runParams Struct
runParams.outputDir = params.outputDir;
runParams.projectFolder = params.projectFolder;
runParams.projectSubfolder = params.projectSubfolder;
runParams.subjectName = params.subjectName;
runParams.sessionDate =params.sessionDate;
runParams.eyeTrackingDir = params.eyeTrackingDir;
runParams.runName = params.runName;
runParams.scaleCalName = ScaleCal.name;

%% Assign the appropriate gaze cal file (if gaze files exist)
if ~isempty(GazeCals)
    if length(GazeCals) == 1
        runParams.gazeCalName = GazeCals.name;
    else
        % sort Gaze Calibration files by timestamp
        [~,idx] = sort([GazeCals.datenum]);
        % get the timestamp for the current run from the corresponding
        % report
        reportFile = dir(fullfile(dropboxDir, params.projectFolder, params.projectSubfolder, ...
            params.subjectName,params.sessionDate,params.eyeTrackingDir,[params.runName '_report.mat']));
        reportTime = reportFile.datenum;
        % take the most recend calibration file acquired before the current run
        for ii = 1: length(idx)
            if GazeCals(idx(ii)).datenum < reportTime
                runParams.gazeCalName = GazeCals(idx(ii)).name;
            else
                continue
            end
        end
    end
end

