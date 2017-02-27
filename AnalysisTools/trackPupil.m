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
if ~isfield(params,'rangeAdjust')
    params.rangeAdjust  = 0.05;
end
if ~isfield(params,'threshVals')
    params.threshVals   = [0.06 0.999];
end
if ~isfield(params,'sharpen')
    params.sharpen   = [20 10];  % sharpen params for PUPIL and GLINT
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
    params.dilateGlint  = 10;
end
if ~isfield(params,'pupilOnly')
    params.pupilOnly    = 0;
end
if ~isfield(params,'pupilFit')
    params.pupilFit    = 'circle';
end


%% Load video
disp('Loading video file, may take a couple minutes...');
inObj                   = VideoReader(params.inVideo);
numFrames               = floor(inObj.Duration*inObj.FrameRate);
grayI                   = zeros([240 320 numFrames],'uint8');
% Convert to gray, resize, crop
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
        sep = strel('disk',1);
        
end

%% Track
progBar = ProgressBar(numFrames,'tracking pupil...');
if isfield(params,'outVideo')
    ih = figure;
end

switch params.pupilFit
    
    case 'circle'
        for i = 1:numFrames
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
                        pupil.strength = pMetric(1);
                        glint.X(i)= gCenters(1,1);
                        glint.Y(i) = gCenters(1,2);
                        glint.size(i) = gRadii(1);
                        glint.strength = gMetric(1);
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
        
        % save full video
        if isfield(params,'outVideo')
            close(ih);
            close(outObj);
        end
        
        % save tracked values to output matrix
        if isfield(params,'outMat')
            save(params.outMat,'pupil','glint');
        end
        
    case 'ellipse'
        for i = 1:numFrames
            % Get the frame
            I = squeeze(grayI(:,:,i));
            
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            
            % Filter for pupil
            % sharpen the image
            pI = imsharpen(I,'amount',params.sharpen(1));
            % Binarize pupil
            binP = zeros(size(pI));
            binP(pI<quantile(double(pI(:)),params.threshVals(1))) = 1;
            %             imshow(binP)
            %             pause
            % remove small objects
            binP = bwareaopen(binP, 1400);
            % if need to track the glint, get a mask based on pupil size
            if ~params.pupilOnly
                maskP = imdilate(binP,1);
            end
            %             imshow(binP)
            %             pause
            % fill Holes
            binP = imfill(binP,'holes');
            
            % get approx mask with find circles
            [pCenters, pRadii]  = imfindcircles(binP,pupilRange,'ObjectPolarity','dark',...
                'Sensitivity',params.sensitivity);
            
            
            
            
            %             imshow(binP)
            %             pause
            % get perimeters of image
            binP = bwperim(binP);
            %                         imshow(binP)
            %             pause
            
            % Fit ellipse to pupil
            [Xp, Yp] = ind2sub(size(binP),find(binP));
            Ep = fit_ellipse(Xp,Yp);
            
            if Ep.long_axis > 0
                [Xp, Yp] = calcEllipse(Ep, 360);
            else
                continue
            end
            
            % Work on the glint
            if ~params.pupilOnly
                
                % Filter for glint
                gI = ones(size(I));
                gI(I<quantile(double(pI(:)),params.threshVals(2))) = 0;
                % Binarize glint
                binG                = zeros(size(gI));
                binG(gI>0.01)       = 1;
                dbinG               = imdilate(binG,se);
                % Binarize glint
                binG = zeros(size(gI));
                binG(gI>0.01)= 1;
                dbinG = imdilate(binG,se);
                % get ROI for glint, based on pupil size
                roiG = immultiply(maskP,dbinG);
                % remove small objects
                dbinG = bwareaopen(roiG, 100);
                % get perimeters of image
                dbinG = bwperim(roiG);
                [Xg, Yg] = ind2sub(size(dbinG),find(dbinG));
                Eg = fit_ellipse(Xg,Yg);
                if Eg.long_axis > 0 && params.pupilOnly == 0
                    [Xg, Yg] = calcEllipse(Eg, 360);
                else
                    continue
                end
            end
            switch params.pupilOnly
                case 0
                    % Remove glints outside the pupil
                    %                     if ~isempty(pCenters) && ~isempty(gCenters)
                    %                         dists           = sqrt( (gCenters(:,1) - pCenters(1,1)).^2 + (gCenters(:,2) - pCenters(1,2)).^2 );
                    %                         gCenters(dists>(1 + params.glintOut)*(pRadii(1)),:) = [];
                    %                         gRadii(dists>(1 + params.glintOut)*(pRadii(1))) = [];
                    %                     end
                    % Visualize the pupil and glint on the image
                    
                    pupil.X(i) = Ep.Y0_in;
                    pupil.Y(i) = Ep.X0_in;
                    pupil.size(i) = Ep.long_axis;
                    glint.X(i) = Eg.Y0_in;
                    glint.Y(i) = Eg.X0_in;
                    ellipse.pupil(i) = Ep;
                    ellipse.glint(i) = Eg;
                    
                    if isfield(params,'outVideo')
                        hold on
                        plot(glint.X(i),glint.Y(i),'+b');
                        hold on
                        plot(Yp, Xp);
                        hold off
                    end
                    
                case 1
                    pupil.X(i) = Ep.Y0_in;
                    pupil.Y(i) = Ep.X0_in;
                    pupil.size(i) = Ep.long_axis;
                    if isfield(params,'outVideo')
                        hold on
                        plot(Yp, Xp);
                        hold off
                    end
            end
            if isfield(params,'outVideo')
                frame                   = getframe(ih);
                writeVideo(outObj,frame);
            end
            if ~mod(i,10);progBar(i);end;
        end
        if isfield(params,'outVideo')
            close(ih);
            close(outObj);
        end
        if isfield(params,'outMat')
            save(params.outMat,'pupil','glint', 'ellipse');
        end
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

