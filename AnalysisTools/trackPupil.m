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
        
        pupilRange              = params.pupilRange;
        glintRange              = params.glintRange;
        pupil.X                 = nan(numFrames,1);
        pupil.Y                 = nan(numFrames,1);
        pupil.size              = nan(numFrames,1);
        glint.X                 = nan(numFrames,1);
        glint.Y                 = nan(numFrames,1);
        glint.size              = nan(numFrames,1);
        % structuring element to dialate the glint
        se                      = strel('disk',params.dilateGlint);
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
        se                      = strel('disk',params.dilateGlint);
        
        
         case 'ellipse2'
        pupil.X = nan(numFrames,1);
        pupil.Y = nan(numFrames,1);
        pupil.size = nan(numFrames,1);
        glint.X = nan(numFrames,1);
        glint.Y = nan(numFrames,1);
        glint.size = nan(numFrames,1);
        ellipse.pupil = nan(numFrames,6);
        ellipse.glint = nan(numFrames,6);
        
        % structuring element to dialate the glint
        se                      = strel('disk',params.dilateGlint);
        
    case 'starburst'
        cr = nan(numFrames,3);
        ellipse = nan(numFrames,5);
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
            % Filter for pupil
            padP                = padarray(I,[size(I,1)/2 size(I,2)/2], 128);
%             h                   = fspecial('gaussian',[filtSize(1) filtSize(2)],filtSize(3));
            pI                  = imsharpen(padP);%padP;%imfilter(padP,h);
            pI = pI(size(I,1)/2+1:size(I,1)/2+size(I,1),size(I,2)/2+1:size(I,2)/2+size(I,2));
            % Binarize pupil
            binP                = ones(size(pI));
            binP(pI<quantile(double(pI(:)),params.threshVals(1))) = 0;
            % remove small objects
            binP = bwareaopen(binP, 1200);
            % get perimeters
            binP = bwperim(binP);
            imshow(binP)
  
            
            % Filter for glint
            gI                  = ones(size(I));
            gI(I<quantile(double(pI(:)),params.threshVals(2))) = 0;
            padG                = padarray(gI,[size(I,1)/2 size(I,2)/2], 0);
%             h                   = fspecial('gaussian',[filtSize(1) filtSize(2)],filtSize(3));
            gI                  = imsharpen(padG);%padG;%imfilter(padG,h);
            gI = gI(size(I,1)/2+1:size(I,1)/2+size(I,1),size(I,2)/2+1:size(I,2)/2+size(I,2));
            % Binarize glint
            binG                = zeros(size(gI));
            binG(gI>0.01)       = 1;
            dbinG               = imdilate(binG,se);
            % Find the pupil
            [pCenters, pRadii]  = imfindcircles(binP,pupilRange,'ObjectPolarity','dark',...
                'Sensitivity',params.sensitivity);
            % Find the glint
            if ~params.pupilOnly
                [gCenters, gRadii]      = imfindcircles(dbinG,glintRange,'ObjectPolarity','bright',...
                    'Sensitivity',params.sensitivity);
            end
            switch params.pupilOnly
                case 0
                    % Remove glints outside the pupil
                    if ~isempty(pCenters) && ~isempty(gCenters)
                        dists           = sqrt( (gCenters(:,1) - pCenters(1,1)).^2 + (gCenters(:,2) - pCenters(1,2)).^2 );
                        gCenters(dists>(1 + params.glintOut)*(pRadii(1)),:) = [];
                        gRadii(dists>(1 + params.glintOut)*(pRadii(1))) = [];
                    end
                    % Visualize the pupil and glint on the image
                    if ~isempty(pCenters) && ~isempty(gCenters)
                        pupil.X(i)      = pCenters(1,1);
                        pupil.Y(i)      = pCenters(1,2);
                        pupil.size(i)   = pRadii(1);
                        glint.X(i)      = gCenters(1,1);
                        glint.Y(i)      = gCenters(1,2);
                        glint.size(i)   = gRadii(1);
                        if isfield(params,'outVideo')
                            viscircles(pCenters(1,:),pRadii(1),'Color','r');
                            hold on
                            plot(gCenters(1,1),gCenters(1,2),'+b');
                            hold off
%                             viscircles(gCenters(1,:),gRadii(1),'Color','b');
                        end
                        pupilRange(1)   = min(floor(pRadii(1)*(1-params.rangeAdjust)),params.pupilRange(2));
                        pupilRange(2)   = max(ceil(pRadii(1)*(1 + params.rangeAdjust)),params.pupilRange(1));
                    else
                        pupilRange(1)   = max(ceil(pupilRange(1)*(1 - params.rangeAdjust)),params.pupilRange(1));
                        pupilRange(2)   = min(ceil(pupilRange(2)*(1 + params.rangeAdjust)),params.pupilRange(2));
                    end
                case 1
                    if ~isempty(pCenters)
                        pupil.X(i)      = pCenters(1,1);
                        pupil.Y(i)      = pCenters(1,2);
                        pupil.size(i)   = pRadii(1);
                        if isfield(params,'outVideo')
                            viscircles(pCenters(1,:),pRadii(1),'Color','r');
                        end
                        pupilRange(1)   = min(floor(pRadii(1)*(1-params.rangeAdjust)),params.pupilRange(2));
                        pupilRange(2)   = max(ceil(pRadii(1)*(1 + params.rangeAdjust)),params.pupilRange(1));
                    else
                        pupilRange(1)   = max(ceil(pupilRange(1)*(1 - params.rangeAdjust)),params.pupilRange(1));
                        pupilRange(2)   = min(ceil(pupilRange(2)*(1 + params.rangeAdjust)),params.pupilRange(2));
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
            save(params.outMat,'pupil','glint');
        end
        
    case 'ellipse'
        for i = 1:30%numFrames
            % Get the frame
            I = squeeze(grayI(:,:,i));
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            % Filter for pupil
            pI = imsharpen(I,'amount',0.1);
            % Binarize pupil
            binP = zeros(size(pI));
            binP(pI<quantile(double(pI(:)),params.threshVals(1))) = 1;
%             % smooth
%             binP = imgaussfilt(binP,2);
%             % convert back to grey image
%             binP = getGrayImage(binP);



            % Filter for glint
            gI  = ones(size(I));
            gI(I<quantile(double(pI(:)),params.threshVals(2))) = 0;
            padG = padarray(gI,[size(I,1)/2 size(I,2)/2], 0);
            gI = imsharpen(padG);
            gI = gI(size(I,1)/2+1:size(I,1)/2+size(I,1),size(I,2)/2+1:size(I,2)/2+size(I,2));
            % Binarize glint
            binG = zeros(size(gI));
            binG(gI>0.01)= 1;
            dbinG = imdilate(binG,se);
            % Find the pupil
            bestFitsPupil  = ellipseDetection(binP,params);
            % Find the glint
            if ~params.pupilOnly
                bestFitsGlint = ellipseDetection(dbinG);
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
                    
                    pupil.X(i) = bestFitsPupil(1,1);
                    pupil.Y(i) = bestFitsPupil(1,2);
                    pupil.size(i) = bestFitsPupil(1,3);
                    glint.X(i) = bestFitsGlint(1,1);
                    glint.Y(i) = bestFitsGlint(1,2);
                    glint.size(i) = bestFitsGlint(1,3);
                    ellipse.pupil(i) = bestFitsPupil;
                    ellipse.glint(i) = bestFitsGlint;
                    
                    if isfield(params,'outVideo')
                        hold on
                        plot(bestFitsGlint(1,1),bestFitsGlint(1,2),'+b');
                        hold on
                        plotEllipse(bestFitsPupil(1,3),bestFitsPupil(1,4),bestFitsPupil(1,5),bestFitsPupil(1,1),bestFitsPupil(1,2));
                        hold off
                    end
                    
                case 1
                    pupil.X(i) = bestFitsPupil(1,1);
                    pupil.Y(i) = bestFitsPupil(1,2);
                    pupil.size(i) = bestFitsPupil(1,3);
                    if isfield(params,'outVideo')
                        hold on
                        plotEllipse(bestFitsPupil(1,3),bestFitsPupil(1,4),bestFitsPupil(1,5),bestFitsPupil(1,1),bestFitsPupil(1,2));
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
      
        
        
    case 'ellipse2'
         for i = 1:numFrames
            % Get the frame
            I = squeeze(grayI(:,:,i));
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
            end
            % Filter for pupil
            pI = imsharpen(I,'amount',2.5);

            imshow (pI)

            % Binarize pupil
            binP = zeros(size(pI));
            binP(pI<quantile(double(pI(:)),params.threshVals(1))) = 1;
            % remove small objects
            binP = bwareaopen(binP, 1000);
           % get perimeters of image
            binP = bwperim(binP);
            % Filter for glint
            gI  = ones(size(I));
            gI(I<quantile(double(pI(:)),params.threshVals(2))) = 0;
            padG = padarray(gI,[size(I,1)/2 size(I,2)/2], 0);
            gI = imsharpen(padG);
            gI = gI(size(I,1)/2+1:size(I,1)/2+size(I,1),size(I,2)/2+1:size(I,2)/2+size(I,2));
            % Binarize glint
            binG = zeros(size(gI));
            binG(gI>0.01)= 1;
            dbinG = imdilate(binG,se);
            
            % Find the pupil
            [Xp, Yp] = ind2sub(size(binP),find(binP));
            E = fit_ellipse(Xp,Yp);
            
            if E.long_axis > 0
                [X, Y] = calcEllipse(E, 360);
            end
            
            % Find the glint
            if ~params.pupilOnly
                bestFitsGlint = ellipseDetection(dbinG);
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
                    
                    pupil.X(i) = E.Y0;
                    pupil.Y(i) = E.X0;
                    pupil.size(i) = E.long_axis;
                    glint.X(i) = bestFitsGlint(1,1);
                    glint.Y(i) = bestFitsGlint(1,2);
                    glint.size(i) = bestFitsGlint(1,3);
                    ellipse.pupil(i) = bestFitsPupil;
                    ellipse.glint(i) = bestFitsGlint;
                    
                    if isfield(params,'outVideo')
                        hold on
                        plot(bestFitsGlint(1,1),bestFitsGlint(1,2),'+b');
                        hold on
                        plotEllipse(bestFitsPupil(1,3),bestFitsPupil(1,4),bestFitsPupil(1,5),bestFitsPupil(1,1),bestFitsPupil(1,2));
                        hold off
                    end
                    
                case 1
                    pupil.X(i) = E.Y0_in;
                    pupil.Y(i) = E.X0_in;
                    pupil.size(i) = E.a *2;
                    if isfield(params,'outVideo')
                        hold on
                        plot(Y, X);
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
        
        
    case 'starburst'
        % reduce noise params
        Ie5 = squeeze(grayI(:,:,5));
        Ie4 = squeeze(grayI(:,:,4));
        Ie3 = squeeze(grayI(:,:,3));
        Ie2 = squeeze(grayI(:,:,2));
        Ie1 = squeeze(grayI(:,:,1));
        normalize_factor = (sum(Ie5,2) + sum(Ie4,2) + sum(Ie3,2) + sum(Ie2,2) + sum(Ie1,2))/(5*size(Ie1,2));
        beta = 0.2;
        % get approx center of the pupil
        I                   = squeeze(grayI(:,:,100));
        %         fig_handle = figure, imshow(uint8(I));
        %         title(sprintf('Please click near the pupil center'));
        %         [cx, cy] = ginput(1);
        cx = 320/2;
        cy = 240/2;
        close(fig_handle);
        
        for i = 1:numFrames
            % Get the frame
            I                   = squeeze(grayI(:,:,i));
            % Show the frame
            if isfield(params,'outVideo')
                imshow(I);
                hold on
            end
            % reduce noise
            [I, normalize_factor] = reduce_noise_temporal_shift(I, normalize_factor, beta);
            pupil_edge_thresh = 20;
            [ellipse(i,:), cr(i,:)] = detect_pupil_and_corneal_reflection(I, cx, cy, pupil_edge_thresh);
            if ~(ellipse(i,1) <= 0 || ellipse(i, 2) <= 0)
                consecutive_lost_count = 0;
                cx = ellipse(i, 3);
                cy = ellipse(i, 4);
            else
                consecutive_lost_count = consecutive_lost_count + 1;
                if consecutive_lost_count >= max_lost_count
                    cx = width/2;
                    cy = height/2;
                end
            end
            % plot cross on glint
            hold on
            plot(cr(i,1,1),cr(i,2,1), '+');
            hold on
            % plot ellipse around pupil
            a = ellipse(i,1,1);
            b = ellipse(i,2,1);
            x0 = ellipse(i,3,1);
            y0 = ellipse(i,4,1);
            t = -pi:0.01:pi;
            x = x0+a*cos(t);
            y = y0+b*sin(t);
            plot(x,y, '.r');
            hold off
            if isfield(params,'outVideo')
                frame  = getframe(ih);
                writeVideo(outObj,frame);
            end
            
            if ~mod(i,10);progBar(i);end;
        end
        if isfield(params,'outVideo')
            close(ih);
            close(outObj);
        end
        if isfield(params,'outMat')
            save(params.outMat,'ellipse','cr');
        end
end

end 


function A = getGrayImage(A)
N = ndims(A);
if (N == 3) % RGB Image
    A = rgb2gray(A);
    if (isinteger(A))
        A = im2single(A); % If A is an integer, cast it to floating-point
    end
    
elseif (N == 2)
    if (islogical(A)) % Binary image
        filtStd = 1.5;
        filtSize = ceil(filtStd*3);
        filtSize = filtSize + ceil(rem(filtSize,2)); % filtSize = Smallest odd integer greater than filtStd*3
        gaussFilt = fspecial('gaussian',[filtSize filtSize],filtStd);
        A = imfilter(im2single(A),gaussFilt,'replicate');
    elseif (isinteger(A))
        A = im2single(A); % If A is an integer, cast it to floating-point
    end
    
else
    iptassert(false,'images:imfindcircles:invalidInputImage'); % This should never happen here.
end

end





