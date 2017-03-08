function [pupil, glint, params] = trackPupil(params)

% Tracks the pupil using an input video file, write out an .avi video
% By default, the video is resized and cropped to have the same aspect
% ratio and size of the original LiveTrack video input.
%
% The default fitting is done with an ellipse, after applying a circular
% mask to the original video. A simple circular fit can be used for
% tracking, but the resulting data appears noisier and generally less
% accurate.
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
%       pupil.circleStrength= strength (accuracy) of the circular mask
%       pupil.ellipse       = parameters of the tracked ellipse
%       glint.X             = X coordinate of glint center (pixels)
%       glint.Y             = Y coordinate of glint center (pixels)
%       glint.size          = radius of glint (pixels)
%       glint.circleStrength= strength (accuracy) of the circular mask
%       glint.ellipse       = parameters of the tracked ellipse
%       params              = struct with all params used for tracking
%
%   Defaults:
%       params.pupilFit     = 'ellipse';    % tracking strategy
%       params.pupilOnly    = 0;            % if 1, no glint is required
%       params.imageSize    = [486 720]/2;; % used to resize input video (for no resizing, just input the native image size [ Y X ] )
%       params.imageCrop    = [1 1 319 239] % used to crop the image
%
%       params.rangeAdjust  = 0.05;         % radius change (+/-) allowed from the previous frame for circular mask
%       params.threshVals   = [0.05 0.999]; % grayscale threshold values for pupil and glint, respectively
%       params.pupilRange   = [10 70];      % initial pupil size range
%       params.glintRange   = [10 30];      % constant glint size range
%       params.glintOut     = 0.1;          % proportion outside of pupil glint is allowed to be. Higher = more outside
%       params.sensitivity  = 0.99;         % [0 1] - sensitivity for 'imfindcircles'. Higher = more circles found
%       params.dilateGlint  = 6;            % used to dialate glint. Higher = more dilation.
%
%       params.ellipseThresh= [0.95 0.9];   % used to threshold the masked image for ellipse tracking
%       params.maskBox      = [4 8];        % used to expand the circular mask for ellipse tracking
%
%   V 2.0 -- Written by Giulia Frazzetta Feb 2017 : general code reorganization,
%   changed default video size, added ellipse option, output eyetracking
%   params.
%   V 1.0 -- Written by Andrew S Bock Sep 2016

%% set defaults

% params to choose the tracking
if ~isfield(params,'pupilFit')
    params.pupilFit = 'ellipse';
end
if ~isfield(params,'pupilOnly')
    params.pupilOnly = 0;
end

% params for image resizing and cropping
if ~isfield(params,'imageSize')
    params.imageSize = [486 720]/2;
end
if ~isfield(params,'imageCrop')
    params.imageCrop = [1 1 319 239];
end

% params for circleFit (always needed)
if ~isfield(params,'rangeAdjust')
    params.rangeAdjust = 0.05;
end
if ~isfield(params,'threshVals')
    params.threshVals = [0.06 0.999];
end
if ~isfield(params,'pupilRange')
    params.pupilRange   = [10 80];
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


% params for ellipse case
if ~isfield(params,'ellipseThresh')
    params.ellipseThresh   = [0.97 0.9];
end
if ~isfield(params,'maskBox')
    params.maskBox   = [4 8];
end

%% Load video
disp('Loading video file, may take a couple minutes...');
inObj                   = VideoReader(params.inVideo);
numFrames               = floor(inObj.Duration*inObj.FrameRate);
% option to overwrite numFrames (for quick testing)
if isfield(params,'forceNumFrames')
    numFrames = params.forceNumFrames;
end

% initialize gray image array
grayI                   = zeros([240 320 numFrames],'uint8');

% Convert to gray, resize, crop to livetrack size
for i = 1:numFrames
    thisFrame           = readFrame(inObj);
    tmp                 = rgb2gray(thisFrame);
    tmp2        = imresize(tmp,params.imageSize);
    tmp3 = imcrop(tmp2,params.imageCrop);
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
        pupil.circleStrength = nan(numFrames,1);
        glint.X = nan(numFrames,1);
        glint.Y = nan(numFrames,1);
        glint.size = nan(numFrames,1);
        glint.circleStrength = nan(numFrames,1);
        
        
    case 'oldEllipse'
        pupilRange = params.pupilRange;
        glintRange = params.glintRange;
        pupil.X = nan(numFrames,1);
        pupil.Y = nan(numFrames,1);
        pupil.size = nan(numFrames,1);
        pupil.circleStrength = nan(numFrames,1);
        pupil.ellipse = nan(numFrames,1);
        glint.X = nan(numFrames,1);
        glint.Y = nan(numFrames,1);
        glint.size = nan(numFrames,1);
        glint.circleStrength = nan(numFrames,1);
        glint.ellipse = nan(numFrames,1);
        
        
        % structuring element for mask size
        sep = strel('rectangle',params.maskBox);
        
    case 'newEllipse'
        pupilRange = params.pupilRange;
        glintRange = params.glintRange;
        pupil.X = nan(numFrames,1);
        pupil.Y = nan(numFrames,1);
        pupil.size = nan(numFrames,1);
        pupil.circleStrength = nan(numFrames,1);
        pupil.ellipse = nan(numFrames,1);
        glint.X = nan(numFrames,1);
        glint.Y = nan(numFrames,1);
        glint.size = nan(numFrames,1);
        glint.circleStrength = nan(numFrames,1);
        glint.ellipse = nan(numFrames,1);
        
        
        % structuring element for mask size
        sep = strel('rectangle',params.maskBox);
        
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
                        pupil.strength(i)  = pMetric(1);
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
        
    case 'oldEllipse'
        for i = 1:numFrames
            % Get the frame
            I = squeeze(grayI(:,:,i));
            
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            
            % track with circles
            [pCenters, pRadii,pMetric, gCenters, gRadii,gMetric, pupilRange, glintRange] = circleFit(I,params,pupilRange,glintRange);
            
            switch params.pupilOnly
                
                % track pupil only
                case 1
                    if isempty(pCenters)
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                    else
                        % get pupil perimeter
                        [binP] = getPupilPerimeter(I,pCenters,pRadii, sep, params);
                        
                        % Fit ellipse to pupil
                        [Xp, Yp] = ind2sub(size(binP),find(binP));
                        Ep = fit_ellipse(Xp,Yp);
                        
                        % store results
                        if ~isempty(Ep) && isempty (Ep.status)
                            pupil.X(i) = Ep.Y0_in;
                            pupil.Y(i) = Ep.X0_in;
                            pupil.size(i) = Ep.long_axis /2; % "radius"
                            % ellipse params
                            pupil.ellipseParams(i) = Ep';
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                        else
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                            
                            % save frame
                            if isfield(params,'outVideo')
                                frame   = getframe(ih);
                                writeVideo(outObj,frame);
                            end
                            if ~mod(i,10);progBar(i);end;
                            continue
                        end
                    end
                    
                    % track pupil and glint
                case 0
                    if isempty(gCenters) && isempty(pCenters)
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                    elseif isempty(pCenters) && ~isempty(gCenters)
                        % circle params for glint
                        glint.circleStrength(i) = gMetric(1);
                        glint.circleRad(i) = gRadii(1);
                        glint.circleX(i) = gCenters(1,1);
                        glint.circleY(i) = gCenters(1,2);
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                        
                    elseif ~isempty(pCenters) && isempty(gCenters)
                        % circle params for pupil
                        pupil.circleStrength(i) = pMetric(1);
                        pupil.circleRad(i) = pRadii(1);
                        pupil.circleX(i) = pCenters(1,1);
                        pupil.circleY(i) = pCenters(1,2);
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                        
                    elseif ~isempty(pCenters) && ~isempty(gCenters)
                        
                        % get pupil perimeter
                        [binP] = getPupilPerimeter(I,pCenters,pRadii, sep, params);
                        
                        % Fit ellipse to pupil
                        [Xp, Yp] = ind2sub(size(binP),find(binP));
                        Ep = fit_ellipse(Xp,Yp);
                        
                        % store results
                        if ~isempty(Ep) && isempty (Ep.status)
                            pupil.X(i) = Ep.Y0_in;
                            pupil.Y(i) = Ep.X0_in;
                            pupil.size(i) = Ep.long_axis /2; % "radius"
                            % ellipse params
                            pupil.ellipseParams(i) = Ep';
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                        else
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                            % save frame
                            if isfield(params,'outVideo')
                                frame   = getframe(ih);
                                writeVideo(outObj,frame);
                            end
                            if ~mod(i,10);progBar(i);end;
                            continue
                        end
                        
                        % track the glint
                        % get glint perimeter
                        [binG] = getGlintPerimeter (I, gCenters, gRadii, params);
                        
                        % Fit ellipse to glint
                        [Xg, Yg] = ind2sub(size(binG),find(binG));
                        Eg = fit_ellipse(Xg,Yg);
                        
                        % store results
                        if ~isempty (Eg) && isempty (Eg.status)
                            glint.X(i) = Eg.Y0_in;
                            glint.Y(i) = Eg.X0_in;
                            glint.circleStrength(i) = gMetric(1);
                            glint.ellipseParams(i) = Eg';
                            % circle params for glint
                            glint.circleStrength(i) = gMetric(1);
                            glint.circleRad(i) = gRadii(1);
                            glint.circleX(i) = gCenters(1,1);
                            glint.circleY(i) = gCenters(1,2);
                        else
                            glint.X(i)= gCenters(1,1);
                            glint.Y(i) = gCenters(1,2);
                            glint.size(i) = gRadii(1);
                            glint.circleStrength(i) = gMetric(1);
                        end
                        % plot results
                        if ~isempty(Ep) && isempty (Ep.status) && Ep.X0_in > 0
                            [Xp, Yp] = calcEllipse(Ep, 360);
                            if isfield(params,'outVideo')
                                hold on
                                plot(Yp, Xp);
                                if ~params.pupilOnly && ~isnan(glint.X(i))
                                    hold on
                                    plot(glint.X(i),glint.Y(i),'+b');
                                end
                                hold off
                            end
                        end
                    end
            end
            
            % save frame
            if isfield(params,'outVideo')
                frame   = getframe(ih);
                writeVideo(outObj,frame);
            end
            if ~mod(i,10);progBar(i);end;
        end
        
    case 'newEllipse'
        for i = 1:numFrames
            % Get the frame
            I = squeeze(grayI(:,:,i));
            
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            
            % track with circles
            [pCenters, pRadii,pMetric, gCenters, gRadii,gMetric, pupilRange, glintRange] = circleFit(I,params,pupilRange,glintRange);
            
            switch params.pupilOnly
                
                % track pupil only
                case 1
                    if isempty(pCenters)
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                    else
                        % get pupil perimeter
                        [binP] = getPupilPerimeter(I,pCenters,pRadii, sep, params);
                        
                        % Fit ellipse to pupil
                        [Xp, Yp] = ind2sub(size(binP),find(binP));
                        Epa = ellipsefit_direct(Xp,Yp);
                        Ep = ellipse_im2ex(Epa);
                        % store results
                        if ~isempty(Ep)
                            pupil.X(i) = Ep(2);
                            pupil.Y(i) = Ep(1);
                            pupil.size(i) = Ep(3); % "radius"
                            % ellipse params
                            pupil.implicitEllipseParams(:,i) = Epa;
                            pupil.explicitEllipseParams(:,i) = Ep;
                            % circle patch params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                        else
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                            
                            % save frame
                            if isfield(params,'outVideo')
                                frame   = getframe(ih);
                                writeVideo(outObj,frame);
                            end
                            if ~mod(i,10);progBar(i);end;
                            continue
                        end
                    end
                    
                    % track pupil and glint
                case 0
                    if isempty(gCenters) && isempty(pCenters)
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                    elseif isempty(pCenters) && ~isempty(gCenters)
                        % circle params for glint
                        glint.circleStrength(i) = gMetric(1);
                        glint.circleRad(i) = gRadii(1);
                        glint.circleX(i) = gCenters(1,1);
                        glint.circleY(i) = gCenters(1,2);
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                        
                    elseif ~isempty(pCenters) && isempty(gCenters)
                        % circle params for pupil
                        pupil.circleStrength(i) = pMetric(1);
                        pupil.circleRad(i) = pRadii(1);
                        pupil.circleX(i) = pCenters(1,1);
                        pupil.circleY(i) = pCenters(1,2);
                        % save frame
                        if isfield(params,'outVideo')
                            frame   = getframe(ih);
                            writeVideo(outObj,frame);
                        end
                        if ~mod(i,10);progBar(i);end;
                        continue
                        
                    elseif ~isempty(pCenters) && ~isempty(gCenters)
                        % get pupil perimeter
                        [binP] = getPupilPerimeter(I,pCenters,pRadii, sep, params);
                        
                        if params.cutPupil
                            % cut the perimeter
                            [Xp, Yp] = ind2sub(size(binP),find(binP));
                            underGlint = find (Xp > gCenters(1,2) - 5 ); %% HARDCODED THRESHOLD HERE
                            
                            if ~isempty(underGlint)
                                binPcut = zeros(size(pI));
                                binPcut(sub2ind(size(binP),Xp(underGlint),Yp(underGlint))) = 1;
%                               imshow(binPcut)
                                binP = binPcut;
                            end
                        end
                        
                        % Fit ellipse to pupil
                        [Xp, Yp] = ind2sub(size(binP),find(binP));
                        XY = [Xp, Yp];
                        try
                            Epa = EllipseDirectFit(XY);
                            Ep = ellipse_alg2geom (Epa);
                        catch ME
                        end
                        if  exist ('ME', 'var')
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                            % save frame
                            if isfield(params,'outVideo')
                                frame   = getframe(ih);
                                writeVideo(outObj,frame);
                            end
                            if ~mod(i,10);progBar(i);end;
                            clear ME
                            continue
                        end
                        % store results
                        if ~isempty(Ep) && isreal(Epa)
                            pupil.X(i) = Ep.Yc;
                            pupil.Y(i) = Ep.Xc;
                            pupil.size(i) = Ep.longAx; % "radius"
                            % ellipse params
                            pupil.ellipseParams(:,i) = Epa;
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                        else
                            % circle params
                            pupil.circleStrength(i) = pMetric(1);
                            pupil.circleRad(i) = pRadii(1);
                            pupil.circleX(i) = pCenters(1,1);
                            pupil.circleY(i) = pCenters(1,2);
                            % save frame
                            if isfield(params,'outVideo')
                                frame   = getframe(ih);
                                writeVideo(outObj,frame);
                            end
                            if ~mod(i,10);progBar(i);end;
                            continue
                        end
                        
                        % track the glint
                        % getGlintPerimeter
                        [binG] = getGlintPerimeter (I, gCenters, gRadii, params);
                        
                        % Fit ellipse to glint
                        [Xg, Yg] = ind2sub(size(binG),find(binG));
                        XYg = [Xg, Yg];
                        try
                            Ega = EllipseDirectFit(XYg);
                            Eg = ellipse_alg2geom (Ega);
                        catch ME
                        end
                        if  exist ('ME', 'var')
                            glint.X(i)= gCenters(1,1);
                            glint.Y(i) = gCenters(1,2);
                            glint.size(i) = gRadii(1);
                            glint.circleStrength(i) = gMetric(1);
                            clear ME
                        end
                        
                        % store results
                        if ~isempty (Eg) && isreal(Ega)
                            glint.X(i) = Eg.Yc;
                            glint.Y(i) = Eg.Xc;
                            glint.circleStrength(i) = gMetric(1);
                            glint.ellipseParams(:,i) = Ega;
                            % circle params for glint
                            glint.circleStrength(i) = gMetric(1);
                            glint.circleRad(i) = gRadii(1);
                            glint.circleX(i) = gCenters(1,1);
                            glint.circleY(i) = gCenters(1,2);
                        else
                            glint.X(i)= gCenters(1,1);
                            glint.Y(i) = gCenters(1,2);
                            glint.size(i) = gRadii(1);
                            glint.circleStrength(i) = gMetric(1);
                        end
                        % plot results
                        if ~isempty(Epa) && Ep.Xc > 0
%                             [Xp, Yp] = calcEllipse(Ep.Xc, Ep.Yc, Ep.longAx, Ep.shortAx, Ep.phi, 360);
                            a = num2str(Epa(1)); 
                            b = num2str(Epa(2));
                            c = num2str(Epa(3));
                            d = num2str(Epa(4));
                            e = num2str(Epa(5));
                            f = num2str(Epa(6));
                            
                            % note that X and Y indices need to be swapped!
                            eqt= ['(',a, ')*y^2 + (',b,')*x*y + (',c,')*x^2 + (',d,')*y+ (',e,')*x + (',f,')'];
                            
                            if isfield(params,'outVideo')
                                hold on
                                h= ezplot(eqt,[1, 240, 1, 320]);
                                set (h, 'Color', 'Red')
                                %                                 plot(Yp, Xp);
                                if ~params.pupilOnly && ~isnan(glint.X(i))
                                    hold on
                                    plot(glint.X(i),glint.Y(i),'+b');
                                end
                                hold off
                            end
                        end
                    end
            end
            
            % save frame
            if isfield(params,'outVideo')
                frame   = getframe(ih);
                writeVideo(outObj,frame);
            end
            if ~mod(i,10);progBar(i);end;
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





