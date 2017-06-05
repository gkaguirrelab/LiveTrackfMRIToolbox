%% clean up
close all
clear
clc

%% define the following
[~, tmpName] = system('whoami');
userName = strtrim(tmpName);

dropboxDir = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab'];
dropboxDir = '~/Desktop';

outDir = ['/Users/' userName '/Desktop'];
dropboxDir=outDir;

%% sample run
params.subjectName = 'TOME_3008';
params.sessionDate = '102116';
params.projectSubfolder = 'session1_restAndStructure';
params.runName = 'rfMRI_REST_AP_run01';

%% set paths
videoPath = fullfile(dropboxDir,'TOME_processing',params.projectSubfolder,params.subjectName,params.sessionDate,'EyeTracking');
videoPath = dropboxDir;
params.inVideo = fullfile(videoPath,[params.runName '_60hz.avi']);
params.outVideo = fullfile(outDir,[params.runName '_perimeter.avi']);



%% tracking params
% params for image resizing and cropping
if ~isfield (params, 'keepOriginalSize')
    params.keepOriginalSize = 0;
end
if ~isfield(params,'imageSize')
    params.imageSize = [486 720]/2;
end
if ~isfield(params,'imageCrop')
    params.imageCrop = [1 1 319 239];
end

% params for circleFit (always needed)
params.rangeAdjust = 0.05;
params.circleThresh = [0.085 0.999];
params.pupilRange   = [20 90];
params.glintRange   = [10 30];
params.glintOut     = 0.1;
params.sensitivity  = 0.99;
params.dilateGlint  = 5;
params.pupilOnly = 0;

% structuring element for pupil mask size
params.maskBox   = [4 30];
sep = strel('rectangle',params.maskBox);

% force number of frames
params.forceNumFrames = 200;
params.ellipseThresh   = [0.9 0.9];
params.gammaCorrection = 1;


%% EXTRACTION OF THE PUPIL PERIMETER
% Load video
disp('Loading video file...');
inObj                   = VideoReader(params.inVideo);
numFrames               = floor(inObj.Duration*inObj.FrameRate);
% option to overwrite numFrames (for quick testing)
if isfield(params,'forceNumFrames')
    numFrames = params.forceNumFrames;
end

% initialize gray image array
grayI                   = zeros([240 320 numFrames],'uint8');

disp('Converting video to standard format, may take a while...');
% Convert to gray, resize, crop to livetrack size
for i = 1:numFrames
    thisFrame           = readFrame(inObj);
    tmp                 = rgb2gray(thisFrame);
    if params.keepOriginalSize == 0
        tmp2 = imresize(tmp,params.imageSize);
        tmp = imcrop(tmp2,params.imageCrop);
    end
    grayI(:,:,i) = tmp;
end

if isfield(params,'outVideo')
    ih = figure;
end
if isfield(params,'outVideo')
    outObj              = VideoWriter(params.outVideo);
    outObj.FrameRate    = inObj.FrameRate;
    open(outObj);
end

clear RGB inObj

% extract perimeter
for i = 1:numFrames
    % Get the frame
    I = squeeze(grayI(:,:,i));
    
    % adjust gamma for this frame
    I = imadjust(I,[],[],params.gammaCorrection);
    
    %     % Show the frame
    %     if isfield(params,'outVideo')
    %         imshow(I);
    %     end
    
    
    % track with circles
    pupilRange = params.pupilRange;
    glintRange = params.glintRange;
    [pCenters, pRadii,pMetric, gCenters, gRadii,gMetric, pupilRange, glintRange] = circleFit(I,params,pupilRange,glintRange);
    % get pupil perimeter
    [binP] = getPupilPerimeter(I,pCenters,pRadii, sep, params);
    
    imshow(binP)
    
    [Xc, Yc] = ind2sub(size(binP),find(binP));
    
    try
        [Epi,~,~] = ellipsefit_bads(Xc,Yc);
%        [Epi,~,~] = ellipsefit(Xc,Yc);
%        Epi = ellipsefit_direct(Xc,Yc);
        Ep = ellipse_im2ex(Epi);
    catch ME
    end
    if  exist ('ME', 'var')
        clear ME
        continue
    end
    
    % store results
    if exist ('Ep','var')
        if ~isempty(Ep) && isreal(Epi)
            % ellipse params
            pupil.implicitEllipseParams(i,:) = Epi';
            pupil.explicitEllipseParams(i,:) = Ep';
        else
            continue
        end
    else
        pupil.implicitEllipseParams(i,:) = NaN;
        pupil.explicitEllipseParams(i,:) = NaN;
    end
    
    % plot
    if ~isempty(Epi) && Ep(1) > 0
        a = num2str(Epi(1));
        b = num2str(Epi(2));
        c = num2str(Epi(3));
        d = num2str(Epi(4));
        e = num2str(Epi(5));
        f = num2str(Epi(6));
        
        % note that X and Y indices need to be swapped!
        eqt= ['(',a, ')*y^2 + (',b,')*x*y + (',c,')*x^2 + (',d,')*y+ (',e,')*x + (',f,')'];
        
        if isfield(params,'outVideo')
            hold on
            h= ezplot(eqt,[1, 240, 1, 320]);
            set (h, 'Color', 'green')
        end
    end
    
    % save frame
    if isfield(params,'outVideo')
        frame   = getframe(ih);
        writeVideo(outObj,frame);
    end
end



% save video
if isfield(params,'outVideo')
    close(ih);
    close(outObj);
end