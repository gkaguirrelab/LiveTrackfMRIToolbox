function [response] = makeResponseStruct(params, dropboxDir)
% header

%% get run params
[runParams] = getRunParams (params,dropboxDir);

%% calibrate and asseble response struct
switch params.trackType
    case 'Hybrid'
        % rescale pupilTrack data
        rescale4calibration(runParams,dropboxDir);
        
        % calibrate
        calParams.trackType = params.trackType;
        calParams.eyeTrackFile =  fullfile(dropboxDir,runParams.outputDir,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,...
            [runParams.runName '_rescaledPupil.mat']);
        calParams.scaleCalFile = fullfile(dropboxDir,runParams.projectFolder,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,runParams.scaleCalName);
        % for early session 1 that do not have a Gaze Cal.
        if isfield(runParams,'gazeCalName')
          calParams.gazeCalFile = fullfile(dropboxDir,runParams.projectFolder,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,runParams.gazeCalName);   
        else
            warning('No gaze calibration file found for this session. Will use the first calibration file available from the subject''s session 2.')
            % look for Gaze Calibration files in session 2
            GazeCals = dir(fullfile(dropboxDir, params.projectFolder, params.projectSubfolderTwo, ...
                params.subjectName,params.sessionTwoDate,params.eyeTrackingDir,'*LTcal*.mat'));
            % sort Gaze Calibration files by timestamp
            [~,idx] = sort([GazeCals.datenum]);
            % take the first GazeCal file
            calParams.gazeCalFile = fullfile(dropboxDir,runParams.projectFolder,params.projectSubfolderTwo,...
                runParams.subjectName,params.sessionTwoDate,runParams.eyeTrackingDir,GazeCals(idx(1)).name);
        end
        
        [pupilSize,gaze] = calcPupilGaze(calParams);
        
        % load timeBase file
        timeBaseFile = fullfile(dropboxDir,'TOME_processing',runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,...
            [runParams.runName '_timeBase.mat']);
        if exist (timeBaseFile,'file')
            load (timeBaseFile);
        else
            warning ('Run skipped because no timebase file was found');
            response = '';
            return
        end
        
        % assemble response struct
        response.pupilSize = pupilSize';
        response.gazeEcc = gaze.ecc;
        response.gazePol = gaze.pol;
        response.timeBase = timeBase.pt;
        response.metadata = runParams;
        response.metadata.eyeTrackFile = calParams.eyeTrackFile;
        response.metadata.scaleCalFile = calParams.scaleCalFile;
        response.metadata.gazeCalFile = calParams.gazeCalFile;
        response.metadata.trackType = calParams.trackType;
end
