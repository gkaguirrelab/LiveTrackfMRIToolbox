function [pupil,glint, params] = trackPupil(params)

% Tracks the pupil using an input video file, write out an .avi video
% By default, the video is resized and cropped to have the same aspect
% ratio and size of the original LiveTrack video input.
%
%   Usage:
%       [pupil,glint,params]       = trackPupil(params)
%
%   Required input:
%       params.inVideo      = '/path/to/inputFile';
%
%   Optional inputs:
%       params.outVideo     = '/path/to/outVideo.avi';
%       params.outMat       = '/path/to/outData.mat'
%
%   Outputs:
%       pupil.X             = X coordinate of pupil center (pixels)
%       pupil.Y             = Y coordinate of pupil center (pixels)
%       pupil.size          = radius of pupil (pixels)
%       glint.X             = X coordinate of glint center (pixels)
%       glint.Y             = Y coordinate of glint center (pixels)
%       glint.size          = radius of glint (pixels)
%
%   Defaults:
%       params.rangeAdjust  = 0.05;         % radius change (+/-) allowed from the previous frame
%       params.threshVals   = [0.05 0.999]; % grayscale threshold values for pupil and glint, respectively
%       params.imageSize    = [486 720]/2;; % used to resize input video
%       params.pupilRange   = [10 70];      % initial pupil size range
%       params.glintRange   = [10 30];      % constant glint size range
%       params.glintOut     = 0.1;          % proportion outside of pupil glint is allowed to be. Higher = more outside
%       params.sensitivity  = 0.99;         % [0 1] - sensitivity for 'imfindcircles'. Higher = more circles found
%       params.dilateGlint  = 6;            % used to dialate glint. Higher = more dilation.
%       params.pupilOnly    = 0;            % if 1, no glint is required
%
%   Written by Andrew S Bock Sep 2016
%   Edited by Giulia Frazzetta Feb 2017 : changed default video size, added
%   ellipse option, output eyetracking params.

%% set defaults

% default tracking strategy
if ~isfield(params,'pupilFit')
    params.pupilFit    = 'circle';
end

% params for circleFit (always needed)
if ~isfield(params,'rangeAdjust')
    params.rangeAdjust  = 0.05;
end
if ~isfield(params,'threshVals')
    params.threshVals   = [0.06 0.999];
end
if ~isfield(params,'imageSize')
    params.imageSize    = [486 720]/2;
end
if ~isfield(params,'pupilRange')
    params.pupilRange   = [10 70];
end
if ~isfield(params,'glintRange')
    params.glintRange   = [10 30];
end
if ~isfield(params,'glintOut')
    params.glintOut     = 0.1;
end
if ~isfield(params,'sensitivity')
    params.sensitivity  = 0.99;
end
if ~isfield(params,'dilateGlint')
    params.dilateGlint  = 5;
end
if ~isfield(params,'pupilOnly')
    params.pupilOnly    = 0;
end

% params for ellipse case
if ~isfield(params,'sharpen')
    params.sharpen   = [5 5];  % sharpen params for PUPIL and GLINT
end

%% Load video
disp('Loading video file, may take a couple minutes...');
inObj                   = VideoReader(params.inVideo);
numFrames               = floor(inObj.Duration*inObj.FrameRate);
grayI                   = zeros([240 320 numFrames],'uint8');

% Convert to gray, resize, crop to livetrack size
for i = 1:numFrames
    thisFrame           = readFrame(inObj);
    tmp                 = rgb2gray(thisFrame);
    tmp2        = imresize(tmp,params.imageSize);
    tmp3 = imcrop(tmp2,[1 1 319 239]);
    grayI(:,:,i) = tmp3;
end

if isfield(params,'outVideo')
    outObj              = VideoWriter(params.outVideo);
    outObj.FrameRate    = inObj.FrameRate;
    open(outObj);
end

clear RGB inObj

%% Initialize pupil and glint structures

switch params.pupilFit
    case 'circle'
        % Useful:
        %   figure;imshow(I);
        %   d = imdistline;
        %   % check size of pupil or glint
        %   delete(d);
        
        pupilRange = params.pupilRange;
        glintRange = params.glintRange;
        pupil.X = nan(numFrames,1);
        pupil.Y = nan(numFrames,1);
        pupil.size = nan(numFrames,1);
        glint.X = nan(numFrames,1);
        glint.Y = nan(numFrames,1);
        glint.size = nan(numFrames,1);
        
    case 'ellipse'
        pupilRange = params.pupilRange;
        glintRange = params.glintRange;
        pupil.X = nan(numFrames,1);
        pupil.Y = nan(numFrames,1);
        pupil.size = nan(numFrames,1);
        glint.X = nan(numFrames,1);
        glint.Y = nan(numFrames,1);
        glint.size = nan(numFrames,1);
        ellipse.pupil = nan(numFrames,6);
        ellipse.glint = nan(numFrames,6);
        
        % structuring element to dialate the glint
        se = strel('disk',params.dilateGlint);
        sep = strel('rectangle',[2 6]);
        
end

%% Track
progBar = ProgressBar(numFrames,'tracking pupil...');
if isfield(params,'outVideo')
    ih = figure;
end

switch params.pupilFit
    
    case 'circle'
        for i = 50:90 %numFrames
            % Get the frame
            I                   = squeeze(grayI(:,:,i));
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            
            % track with circles
            [pCenters, pRadii,pMetric, gCenters, gRadii,gMetric, pupilRange, glintRange] = circleFit(I,params,pupilRange,glintRange);
            
            % visualize tracking results
            switch params.pupilOnly
                case 0
                    if ~isempty(pCenters) && ~isempty(gCenters)
                        pupil.X(i) = pCenters(1,1);
                        pupil.Y(i) = pCenters(1,2);
                        pupil.size(i) = pRadii(1);
                        pupil.circleStrength(i) = pMetric(1);
                        glint.X(i)= gCenters(1,1);
                        glint.Y(i) = gCenters(1,2);
                        glint.size(i) = gRadii(1);
                        glint.circleStrength(i) = gMetric(1);
                        if isfield(params,'outVideo')
                            viscircles(pCenters(1,:),pRadii(1),'Color','r');
                            hold on
                            plot(gCenters(1,1),gCenters(1,2),'+b');
                            hold off
                        end
                    end
                case 1
                    if ~isempty(pCenters)
                        pupil.X(i)      = pCenters(1,1);
                        pupil.Y(i)      = pCenters(1,2);
                        pupil.size(i)   = pRadii(1);
                        pupil.strength  = pMetric(1);
                        if isfield(params,'outVideo')
                            viscircles(pCenters(1,:),pRadii(1),'Color','r');
                        end
                    end
            end
            
            % save single frame
            if isfield(params,'outVideo')
                frame                   = getframe(ih);
                writeVideo(outObj,frame);
            end
            if ~mod(i,10);progBar(i);end;
        end
        
    case 'ellipse'
        for i = 1:numFrames
            % Get the frame
            I = squeeze(grayI(:,:,i));
            
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            
            % track with circles
            [pCenters, pRadii,pMetric, gCenters, gRadii,gMetric, pupilRange, glintRange] = circleFit(I,params,pupilRange,glintRange);
            
            if isNan(pCenters(1,:))
                continue
            else
                % create a mask from circle fitting parameters
                pupilMask = zeros(size(I));
                pupilMask = insertShape(pupilMask,'FilledCircle',[pCenters(1,1) pCenters(1,2) pRadii(1)],'Color','white');
                pupilMask = imdilate(pupilMask,sep);
                pupilMask = im2bw(pupilMask);
                
                % apply mask to grey image complement image
                cI = imcomplement(I);
                maskedPupil = immultiply(cI,pupilMask);
                
                % sharpen the image
                pI = maskedPupil; %imsharpen(maskedPupil,'amount',params.sharpen(1));
                
                % convert back to gray
                pI = uint8(pI);
                % Binarize pupil
                binP = ones(size(pI));
                nonZeroPI = find (pI);
                binP(pI<quantile(double(pI(nonZeroPI)),0.2)) = 0;
                imshow(binP)
                
                % remove small objects
                binP = bwareaopen(binP, 500);
                
                % fill the holes
                binP = imfill(binP,'holes');
                
                % get perimeter of object
                binP = bwperim(binP);
                
                % Fit ellipse to pupil
                [Xp, Yp] = ind2sub(size(binP),find(binP));
                Ep = fit_ellipse(Xp,Yp);
                
                % store results
                if Ep.long_axis > 0
                    pupil.X(i) = Ep.Y0_in;
                    pupil.Y(i) = Ep.X0_in;
                    pupil.size(i) = Ep.long_axis;
                    pupil.circleStrength(i) = pMetric(1);
                    pupil.ellipseParams(i) = Ep;
                else
                    continue
                end
                
                % track the glint
                if ~params.pupilOnly
                    % create a mask from circle fitting parameters (note: glint
                    % is already dilated
                    glintMask = zeros(size(I));
                    glintMask = insertShape(glintMask,'FilledCircle',[gCenters(1,1) gCenters(1,2) gRadii(1)],'Color','white');
                    glintMask = im2bw(glintMask);
                    
                    % apply mask to grey image
                    maskedGlint = immultiply(I,glintMask);
                    imshow (maskedGlint)
                    
                    % convert back to gray
                    gI = uint8(maskedGlint);
                    
                    % Binarize glint
                    binG  = ones(size(gI));
                    nonZeroGI = find (gI);
                    binG(gI<quantile(double(gI(nonZeroGI)),0.95)) = 0;
                    imshow(binG)
                    
                    % get perimeter of glint
                    binG = bwperim(binG);
                    
                    % Fit ellipse to glint
                    [Xg, Yg] = ind2sub(size(binG),find(binG));
                    Eg = fit_ellipse(Xg,Yg);
                    
                    % store results
                    glint.X(i) = Eg.Y0_in;
                    glint.Y(i) = Eg.X0_in;
                    glint.circleStrength(i) = gMetric(1);
                    glint.ellipseParams(i) = Eg;
                end
                
                % plot results
                if Ep.long_axis > 0
                    [Xp, Yp] = calcEllipse(Ep, 360);
                    if isfield(params,'outVideo')
                        hold on
                        plot(Yp, Xp);
                        if ~params.pupilOnly
                            hold on
                            plot(glint.X(i),glint.Y(i),'+b');
                        end
                        hold off
                    end
                else
                    continue
                end
                
                % save frame
                if isfield(params,'outVideo')
                    frame   = getframe(ih);
                    writeVideo(outObj,frame);
                end
                if ~mod(i,10);progBar(i);end;
            end
        end
end
% save full video
if isfield(params,'outVideo')
    close(ih);
    close(outObj);
end

% save tracked values to output matrix
if isfield(params,'outMat')
    save(params.outMat,'pupil','glint');
end



end



function [pCenters, pRadii,pMetric, gCenters, gRadii,gMetric, pupilRange, glintRange] = circleFit(I,params,pupilRange,glintRange)

% create blurring filter
filtSize = round([0.01*min(params.imageSize) 0.01*min(params.imageSize) 0.01*min(params.imageSize)]);

% structuring element to dialate the glint
se = strel('disk',params.dilateGlint);

% Filter for pupil
padP = padarray(I,[size(I,1)/2 size(I,2)/2], 128);
h = fspecial('gaussian',[filtSize(1) filtSize(2)],filtSize(3));
pI = imfilter(padP,h);
pI = pI(size(I,1)/2+1:size(I,1)/2+size(I,1),size(I,2)/2+1:size(I,2)/2+size(I,2));
% Binarize pupil
binP = ones(size(pI));
binP(pI<quantile(double(pI(:)),params.threshVals(1))) = 0;

% Filter for glint
gI = ones(size(I));
gI(I<quantile(double(pI(:)),params.threshVals(2))) = 0;
padG = padarray(gI,[size(I,1)/2 size(I,2)/2], 0);
h = fspecial('gaussian',[filtSize(1) filtSize(2)],filtSize(3));
gI = imfilter(padG,h);
gI = gI(size(I,1)/2+1:size(I,1)/2+size(I,1),size(I,2)/2+1:size(I,2)/2+size(I,2));
% Binarize glint
binG  = zeros(size(gI));
binG(gI>0.01) = 1;
dbinG = imdilate(binG,se);

% Find the pupil
[pCenters, pRadii,pMetric] = imfindcircles(binP,pupilRange,'ObjectPolarity','dark',...
    'Sensitivity',params.sensitivity);
% Find the glint
if ~params.pupilOnly
    [gCenters, gRadii,gMetric] = imfindcircles(dbinG,glintRange,'ObjectPolarity','bright',...
        'Sensitivity',params.sensitivity);
else
    gCenters = [NaN NaN];
    gRadii = NaN;
    gMetric = NaN;
end

% Remove glints outside the pupil
if ~params.pupilOnly
    if ~isempty(pCenters) && ~isempty(gCenters)
        dists           = sqrt( (gCenters(:,1) - pCenters(1,1)).^2 + (gCenters(:,2) - pCenters(1,2)).^2 );
        gCenters(dists>(1 + params.glintOut)*(pRadii(1)),:) = [];
        gRadii(dists>(1 + params.glintOut)*(pRadii(1))) = [];
    end
end

% adjust the pupil range (for quicker processing)
if ~isempty(pCenters)
    pupilRange(1)   = min(floor(pRadii(1)*(1-params.rangeAdjust)),params.pupilRange(2));
    pupilRange(2)   = max(ceil(pRadii(1)*(1 + params.rangeAdjust)),params.pupilRange(1));
else
    pupilRange(1)   = max(ceil(pupilRange(1)*(1 - params.rangeAdjust)),params.pupilRange(1));
    pupilRange(2)   = min(ceil(pupilRange(2)*(1 + params.rangeAdjust)),params.pupilRange(2));
end

end

