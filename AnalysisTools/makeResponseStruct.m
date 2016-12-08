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
        calParams.eyeTrackFile =  fullfile(dropboxDir,runParams.outputDir,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,...
            [runParams.runName '_rescaledPupil.mat']);
        calParams.scaleCalFile = fullfile(dropboxDir,runParams.projectFolder,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,runParams.scaleCalName);
        calParams.gazeCalFile = fullfile(dropboxDir,runParams.projectFolder,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,runParams.gazeCalName);
        calParams.trackType = params.trackType;
        [pupilSize,gaze] = calcPupilGaze(calParams);
        
        % load timeBase file
        timeBaseFile = fullfile(dropboxDir,'TOME_processing',runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,...
            [runParams.runName '_timeBase.mat']);
        if exist (timeBaseFile,'file')
            load (timeBaseFile);
        else
            warning ('Run skipped because no timebase file was found');
            response = 0;
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
