function sizeConversionFactor = sizeCalibration(params)

%% load files
scaleCalFile = dir(fullfile(dropboxDir, params.projectFolder, params.projectSubfolder, ...
    params.subjectName,params.sessionDate,params.eyeTrackingDir,'*ScaleCal*.mat'));

% load scaleScal file
LT = load(fullfile(scaleCalFile.folder,scaleCalFile.name));

% load all scale Cal Video
rawVids = dir(fullfile(dropboxDir, 'TOME_processing', params.projectSubfolder, ...
    params.subjectName,params.sessionDate,params.eyeTrackingDir,'RawScaleCal*_60hz.avi'));

if isempty(rawVids)
    LTvids = dir(fullfile(dropboxDir, params.projectFolder, params.projectSubfolder, ...
        params.subjectName,params.sessionDate,params.eyeTrackingDir,'*ScaleCal*.avi'));
end


%% track
if ~isempty(rawVids)
    for rr = 1: length(rawVids)
        fprintf ('\nProcessing calibration %d of %d\n',rr,length(rawVids))
        %get the run name
        params.calName = rawVids(rr).name(1:end-9); %runs
        outDir = fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking');
        params.acqRate = 60;
        params.pupilFit = 'ellipse';
        params.ellipseThresh   = [0.94 0.9];
        params.circleThresh = [0.05 0.999];
        params.inVideo = fullfile(outDir,[params.calName '_60hz.avi']);
        params.outVideo = fullfile(outDir,[params.calName '_calTrack.avi']);
        params.outMat = fullfile(outDir, [params.calName '_calTrack.mat']);
        params.pupilOnly = 1;
        params.cutPupil = 1;
        [dotsPX(rr), ~, ~] = trackPupil(params);
    end
else
    % if no raw videos were acquired (early scans), track the livetrack videos
    for rr = 1: length(LTids)
        fprintf ('\nProcessing calibration %d of %d\n',rr,length(LTids))
        %get the run name
        params.calName = LTvids(rr).name(1:end-4); %runs
        outDir = fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking');
        params.acqRate = 10;
        params.pupilFit = 'ellipse';
        params.ellipseThresh   = [0.94 0.9];
        params.circleThresh = [0.05 0.999];
        params.inVideo = fullfile(outDir,[params.calName '_60hz.avi']);
        params.outVideo = fullfile(outDir,[params.calName '_calTrack.avi']);
        params.outMat = fullfile(outDir, [params.calName '_calTrack.mat']);
        params.pupilOnly = 1;
        params.cutPupil = 1;
        [dotsPX(rr), ~, ~] = trackPupil(params);
    end
end

%% get the pixels per mm
diameters = fliplr(LT.ScaleCal.pupilDiameterMmGroundTruth);

for rr = 1: length(rawVids)
    PXperMM(rr) = median(dotsPX(rr).size) / diameters(rr);
end

sizeConversionFactor = median(PXperMM);

%% save out size conversion factor as a mat file
 save (fullfile(outDir, 'sizeConversionFactor.mat'), 'sizeConversionFactor')