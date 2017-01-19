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
            runParams.gazeCalName = GazeCals(idx(1)).name;
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
        
        % assemble response struct values
        response.pupilSize = pupilSize';
        response.gazeEcc = gaze.ecc;
        response.gazePol = gaze.pol;
        response.gazeX = gaze.X';
        response.gazeY = gaze.Y';
        response.timeBase = timeBase.pt;
        
        % check that the timebase and the response are the same length
        if length(response.pupilSize)~=length(response.timeBase)
            warning ('Timebase and response values are not of the same length')
        end
        
        % metadata
        response.metadata = runParams;
        response.metadata.eyeTrackFile = fullfile(runParams.outputDir,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,...
            [runParams.runName '_rescaledPupil.mat']);
        response.metadata.scaleCalFile = fullfile(runParams.projectFolder,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,runParams.scaleCalName);
        response.metadata.gazeCalFile = fullfile(runParams.projectFolder,runParams.projectSubfolder,...
            runParams.subjectName,runParams.sessionDate,runParams.eyeTrackingDir,runParams.gazeCalName);
        response.metadata.trackType = calParams.trackType;
        
       % git info
       % LiveTrack toolbox
       fCheck = which('GetGitInfo');
       if ~isempty(fCheck)
           thePath = fileparts(mfilename('fullpath'));
           gitInfo = GetGITInfo(thePath);
       else
           gitInfo = 'function ''GetGITInfo'' not found';
       end
      response.metadata.gitInfo = gitInfo;
      
end
