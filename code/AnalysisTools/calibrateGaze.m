
function calParams = calibrateGaze (params)


if ~isfield(params,'viewDist')
    params.viewDist = 1065;
end


fps = 60; % fps


trackData = load(params.trackedData);% = load ('/Volumes/Bay_2_data/giulia/Dropbox-Aguirre-Brainard-Lab/TOME_processing/session2_spatialStimuli/TOME_3008/103116/EyeTracking/GazeCal02_testTracking.mat');
LTdata = load(params.LTcal); %load('/Volumes/Bay_2_data/giulia/Dropbox-Aguirre-Brainard-Lab/TOME_data/session2_spatialStimuli/TOME_3008/103116/EyeTracking/GazeCal02_LTdat.mat');

load(params.rawVidStart) %'/Volumes/Bay_2_data/giulia/Dropbox-Aguirre-Brainard-Lab/TOME_data/session2_spatialStimuli/TOME_3008/103116/EyeTracking/GazeCal02_rawVidStart.mat');

%% get the fixation data

% get each target duration on screen
TarTimesFromStart  = round(LTdata.dotTimes - rawVidStart) * fps;

targetDurSec = diff(LTdata.dotTimes); % target duration in seconds

targetDurFrames = round(targetDurSec * fps);
videoStartFrames = round(LTdata.dotTimes(1) - rawVidStart) * fps;
totalFrames = round(LTdata.dotTimes(end) - rawVidStart) * fps;


% % remove 25% boundaries
% removeFrames = round(targetDurFrames ./4);
% 
% for ct = 1 :9
%     meanP.X(ct) = nanmedian(trackData.pupil.X(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     meanP.Y(ct) = nanmedian(trackData.pupil.Y(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     meanG.X(ct) = nanmedian(trackData.glint.X(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     meanG.Y(ct) = nanmedian(trackData.glint.Y(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     
%     stdP.X(ct) = nanstd(trackData.pupil.X(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     stdP.Y(ct) = nanstd(trackData.pupil.Y(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     stdG.X(ct) = nanstd(trackData.glint.X(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
%     stdG.Y(ct) = nanstd(trackData.glint.Y(TarTimesFromStart(ct) + removeFrames(ct) :TarTimesFromStart(ct+1) - removeFrames(ct)));
% 
% end

% make moving mean on window with 20% of samples
window = round(targetDurFrames ./5);
for ct = 1 :9
    movMeanP.X= movmedian(trackData.pupil.X(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    movMeanP.Y = movmedian(trackData.pupil.Y(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    movMeanG.X = movmedian(trackData.glint.X(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    movMeanG.Y = movmedian(trackData.glint.Y(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    
    movStdP.X = movstd(trackData.pupil.X(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    movStdP.Y = movstd(trackData.pupil.Y(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    movStdG.X = movstd(trackData.glint.X(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');
    movStdG.Y = movstd(trackData.glint.Y(TarTimesFromStart(ct) :TarTimesFromStart(ct+1)), window(ct),'omitnan','Endpoints','discard');

    % ger minimum std
    [minPX,Xidx] = min(movStdP.X);
    [minPY,Yidx] = min(movStdP.Y);
    
    % take according to x
    meanP.X(ct) = movMeanP.X(Xidx);
    meanP.Y(ct) = movMeanP.Y(Xidx);
    meanG.X(ct) = movMeanG.X(Xidx);
    meanG.Y(ct) = movMeanG.Y(Xidx);
end


% get data ready for calibration
calParams.pupil.X = meanP.X';
calParams.pupil.Y = meanP.Y';
calParams.glint.X = meanG.X';
calParams.glint.Y = meanG.Y';

% Calculate the 'CalMat'
calParams.targets.X     = LTdata.targets(:,1); % mm on screen, screen center = 0
calParams.targets.Y     = LTdata.targets(:,2); % mm on screen, screen center = 0
calParams.viewDist      = params.viewDist; % mm from screen
% Calculate the adjustment factor
calParams.rpc           = calcRpc(calParams);
% Calculate the transformation matrix
[calParams.calMat]      = calcCalMat(calParams);
calGaze                 = calcGaze(calParams);
figure;
hold on;

% plot each true and tracked target position. Red cross means target
% position and blue means tracked gaze position.
for i = 1:length(calGaze.X)
    plot(LTdata.targets(i,1), LTdata.targets(i,2),'rx');
    plot(calGaze.X(i),calGaze.Y(i),'bx');
    plot([LTdata.targets(i,1) calGaze.X(i)], [LTdata.targets(i,2) calGaze.Y(i)],'g');
end