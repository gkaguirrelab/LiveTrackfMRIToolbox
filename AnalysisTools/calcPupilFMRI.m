function [pupilSize,gaze] = calcPupilFMRI(params)

% Calculates the pupil size and gaze position from eye tracking data
% collected during an fMRI run
%
%   Usage:
%       [pupilSize,gaze] = calcPupilFMRI(params)
%
%   If params.trackType == 'LiveTrack' <default>
%
%       Required inputs:
%           params.scaleCalFile     - full path to scale calibration .mat file
%           params.gazeCalFile      - full path to scale calibration .mat file
%           params.fMRIMatFile      - full path to fMRI run .mat file
%
%   If params.trackType == 'trackPupil'
%
%       Required inputs:
%           params.scaleCalVideo    - full path to scale calibration .avi movie file
%           params.calTargetFile    - full path to gaze calibration LTdat.mat file
%           params.gazeCalVideo     - full path to gaze calibration .mov/.avi movie file
%           params.fMRIVideo        - full path to fMRI run .avi movie file
%
%   Defaults:
%       params.scaleSize        - 5;        % calibration dot size (mm)
%       params.vidBuffer        - 0.25;     % proportion of the gazeCalVideo to crop
%       params.viewDist         - 1065;     % distance from eyes to screen (mm)
%       params.trackType        - 'LiveTrack' (other option is 'trackPupil')
%
%   Outputs:
%       pupilSize               - vector of pupil sizes (mm)
%       gaze.X                  - vector of gaze X coordinates (mm)
%       gaze.Y                  - vector of gaze Y coordinates (mm)
%       gaze.ecc                - vector of gaze eccentricity values (degrees visual angle)
%       gaze.pol                - vector of gaze polar angle values (degrees)
%
%   Note about blinks:
%
%       If params.trackType == 'LiveTrack'
%           User must filter these out post-hoc, as the LiveTrack assigns a
%           value to the pupil and glint no matter what
%
%       If params.trackType == 'trackPupil'
%           nans in the output data indicate a blink, or really any event 
%           where both the pupil and glint could not be simultaneously 
%           tracked
%
%   Written by Andrew S Bock Oct 2016

%% set defaults
if ~isfield(params,'scaleSize')
    params.scaleSize = 5;
end
if ~isfield(params,'vidBuffer')
    params.vidBuffer = 0.25;
end
if ~isfield(params,'viewDist')
    params.viewDist = 1065;
end
if ~isfield(params,'trackType')
    params.trackType = 'LiveTrack';
end
%% Get the mm / pixel from calibration stick
switch params.trackType
    case 'trackPupil'
        scaleParams.inVideo     = params.scaleCalVideo;
        if isfield(params,'scaleCalOutVideo');
            scaleParams.outVideo  = params.scaleCalOutVideo;
        end
        if isfield(params,'scaleCalOutMat');
            scaleParams.outMat  = params.scaleCalOutMat;
        end
        scaleParams.pupilRange  = params.scaleSize * [3 10];
        scaleParams.threshVals  = [0.05 0.999]; % bin for pupil and glint, respectively
        scaleParams.pupilOnly   = 1;
        [scalePupil]            = trackPupil(scaleParams);
        mmPerPixel              = params.scaleSize / median(scalePupil.size);
    case 'LiveTrack'
        scaleCal                = load(params.scaleCalFile);
        [maxVal,maxInd]         = max(scaleCal.ScaleCal.pupilDiameterMmGroundTruth);
        mmPerPixel              = maxVal / median([scaleCal.ScaleCal.ReportRaw{maxInd}.PupilWidth_Ch01]);
end
%% Get the transformation matrix for gaze
switch params.trackType
    case 'trackPupil'
        % Track the pupil and glint in the gaze calibration movie
        gazeParams.inVideo      = params.gazeCalVideo;
        if isfield(params,'gazeCalOutVideo')
            gazeParams.outVideo = params.gazeCalOutVideo;
        end
        if isfield(params,'gazeCalOutMat')
            gazeParams.outMat = params.gazeCalOutMat;
        end
        [gazePupil,gazeGlint]   = trackPupil(gazeParams);
        % The movie is manually stopped, so there is too much video at the end
        % after the dots are gone
        pad                     = round(params.vidBuffer*length(gazePupil.X));
        gazePupil.X             = gazePupil.X(1:end-pad);
        gazePupil.Y             = gazePupil.Y(1:end-pad);
        gazePupil.size          = gazePupil.size(1:end-pad);
        gazeGlint.X             = gazeGlint.X(1:end-pad);
        gazeGlint.Y             = gazeGlint.Y(1:end-pad);
        gazeGlint.size          = gazeGlint.size(1:end-pad);
        % Pull out pupil and glint values for each point
        nPoints                 = 20; % last nPoints
        prevPoints              = zeros(nPoints,2);
        prevDist                = nan(size(gazePupil.X));
        for i = 1:length(gazePupil.X)
            clear tmpDist
            for j = 1:nPoints
                tmpDist(j)      =  sqrt( (gazePupil.X(i) - prevPoints(j,1))^2 + ...
                    (gazePupil.Y(i) - prevPoints(j,2))^2 );
            end
            prevDist(i)         = nanmean(tmpDist);
            prevPoints          = [prevPoints(2:end,:);[gazePupil.X(i),gazePupil.Y(i)]];
        end
        % Thresh the distances
        % Look at this plot, confirm the clusters are accurate
        thresh                  = nPoints/10;
        k                       = 9;
        goodInd                 = prevDist<thresh;
        gazePupilX              = gazePupil.X(goodInd);
        gazePupilY              = gazePupil.Y(goodInd);
        gazeGlintX              = gazeGlint.X(goodInd);
        gazeGlintY              = gazeGlint.Y(goodInd);
        % Provide the starting points for the dot search
        Xs                      = [min(gazePupilX), min(gazePupilX) + ...
            (max(gazePupilX) - min(gazePupilX))/2, max(gazePupilX)];
        Ys = [min(gazePupilY), min(gazePupilY) + ...
            (max(gazePupilY) - min(gazePupilY))/2, max(gazePupilY)];
        dotMatrix = [...
            Xs(1),Ys(1); ...
            Xs(1),Ys(2); ...
            Xs(1),Ys(3); ...
            Xs(2),Ys(1); ...
            Xs(2),Ys(2); ...
            Xs(2),Ys(3); ...
            Xs(3),Ys(1); ...
            Xs(3),Ys(2); ...
            Xs(3),Ys(3); ...
            ];
        % cluster the data
        idx = kmeans([gazePupilX,gazePupilY],k,'Start',dotMatrix);
        % Plot the means
        gazePupilMeans          = nan(k,2);
        gazeGlintMeans          = nan(k,2);
        fullFigure;
        for i = 1:k
            subplot(3,3,i);
            plot(gazePupilX,gazePupilY,'.','MarkerSize',20);
            axis square;
            hold on;
            title(['Cluster = ' num2str(i)],'FontSize',20);
            gazePupilMeans(i,1) = mean(gazePupilX(idx==i));
            gazePupilMeans(i,2) = mean(gazePupilY(idx==i));
            gazeGlintMeans(i,1) = mean(gazeGlintX(idx==i));
            gazeGlintMeans(i,2) = mean(gazeGlintY(idx==i));
            plot(gazePupilMeans(i,1),gazePupilMeans(i,2),'.r','MarkerSize',10);
            plot(gazeGlintMeans(i,1),gazeGlintMeans(i,2),'.g','MarkerSize',10);
        end
        % Pull out the pupil, glint, and target values
        gazeCal                 = load(params.calTargetFile);
        targets                 = gazeCal.targets;
        % Re-order pupil and glint to match order of targets (only if using 'trackPupil' and above code)
        uTX = unique(targets(:,1));
        uTY = unique(targets(:,2));
        ct = 0;
        for i = 1:length(uTX)
            for j = 1:length(uTY)
                ct = ct + 1;
                targInd = find(targets(:,1) == uTX(i) & targets(:,2) == uTY(j));
                calParams.pupil.X(targInd) = gazePupilMeans(ct,1);
                calParams.pupil.Y(targInd) = gazePupilMeans(ct,2);
                calParams.glint.X(targInd) = gazeGlintMeans(ct,1);
                calParams.glint.Y(targInd) = gazeGlintMeans(ct,2);
            end
        end
        % Calculate the 'CalMat'
        calParams.targets.X     = targets(:,1); % mm on screen, screen center = 0
        calParams.targets.Y     = targets(:,2); % mm on screen, screen center = 0
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
            plot(targets(i,1), targets(i,2),'rx');
            plot(calGaze.X(i),calGaze.Y(i),'bx');
            plot([targets(i,1) calGaze.X(i)], [targets(i,2) calGaze.Y(i)],'g');
        end
    case 'LiveTrack'
        gazeCal                 = load(params.gazeCalFile);
        calParams.rpc           = gazeCal.Rpc;
        calParams.calMat        = gazeCal.CalMat;
end
%% Get the pupil size and gaze location from an fMRI run
switch params.trackType
    case 'trackPupil'
        runParams.inVideo       = params.fMRIVideo;
        if isfield(params,'fMRIOutVideo');
            runParams.outVideo  = params.fMRIOutVideo;
        end
        if isfield(params,'fMRIOutMat');
            runParams.outMat    = params.fMRIOutMat;
        end
        [runPupil,runGlint]     = trackPupil(runParams);
        runParams.pupil.X       = runPupil.X;
        runParams.pupil.Y       = runPupil.Y;
        runParams.glint.X       = runGlint.X;
        runParams.glint.Y       = runGlint.Y;
        runParams.viewDist      = params.viewDist;
        runParams.rpc           = calParams.rpc;
        runParams.calMat        = calParams.calMat;
    case 'LiveTrack'
        fMRImat                 = load(params.fMRIMatFile);
        runPupil.size           = [];
        runParams.pupil.X       = [];
        runParams.pupil.Y       = [];
        runParams.glint.X       = [];
        runParams.glint.Y       = [];
        for i = 1:length(fMRImat.Report)
            % pupil size
            runPupil.size       = [runPupil.size;...
                fMRImat.Report(i).PupilWidth_Ch01;fMRImat.Report(i).PupilWidth_Ch02];
            % pupil X
            runParams.pupil.X       = [runParams.pupil.X;...
                fMRImat.Report(i).PupilCameraX_Ch01;fMRImat.Report(i).PupilCameraX_Ch02];
            % pupil Y
            runParams.pupil.Y       = [runParams.pupil.Y;...
                fMRImat.Report(i).PupilCameraY_Ch01;fMRImat.Report(i).PupilCameraY_Ch02];
            % glint X
            runParams.glint.X       = [runParams.glint.X;...
                fMRImat.Report(i).Glint1CameraX_Ch01;fMRImat.Report(i).Glint1CameraX_Ch02];
            % glint Y
            runParams.glint.Y       = [runParams.glint.Y;...
                fMRImat.Report(i).Glint1CameraY_Ch01;fMRImat.Report(i).Glint1CameraY_Ch02];
        end
        runParams.viewDist      = params.viewDist;
        runParams.rpc           = calParams.rpc;
        runParams.calMat        = calParams.calMat;
end
runGaze                 = calcGaze(runParams);
%% Set outputs
pupilSize               = runPupil.size * mmPerPixel;
gaze                    = runGaze;