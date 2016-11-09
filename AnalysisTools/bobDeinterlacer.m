function bobDeinterlacer

% This function allows to deinterlace NTSC DV video, saving out a
% progressive 60 Hz video.
%
%  These deinterlace strategies are available (bobMode):
% 'Raw'    =  extract 2 fields for every frame. Save progressive video.
%             Final spatial resolution is half the original resolution.
% 'Zero'   =  extract 2 fields for every frame. Alternate every row with a
%             row of zeros to preserve aspect ratio.
% 'Double' =  extract 2 fields for every frame. Duplicate each raw to
%             preserve aspect ratio.
% 'Mean'   =  extract 2 fields for every frame. Add a row with the mean of
%             two consecutive rows to preserve aspect ratio.

% References on Bob technique for deinterlacing and on deinterlacing in
% general:
% https://www.altera.com/content/dam/altera-www/global/en_US/pdfs/literature/wp/wp-01117-hd-video-deinterlacing.pdf
% http://www.100fps.com/
%% NEED TO TURN THESE INTO INPUTS
% Get user name
[~, tmpName]            = system('whoami');
userName                = strtrim(tmpName);
dbDir                   = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab'];
% Set the subject / session / run
sessName                = 'session1_restAndStructure';
subjName                = 'TOME_3007';
sessDate                = '101116';
reportName              = 'rfMRI_REST_AP_run01_report.mat';
videoName               = 'rfMRI_REST_AP_run01_raw.mov';
outVideoFile            = fullfile('~','testVideo.avi');
sessDir                 = fullfile(dbDir,'TOME_data',sessName,subjName,sessDate,'EyeTracking');

nFrames                 = 1000;


inObj                   = VideoReader(fullfile(sessDir,videoName));
bobMode                 = 'Mean';
% bobMode can be Raw,Zero,Duplicate or Mean.

Bob               = VideoWriter(['/Users/' userName '/Desktop/Bob_' bobMode '.avi']);
Bob.FrameRate      = 60;
Bob.Quality        = 100;


%%
progBar = ProgressBar(nFrames,'Making movie...');
open(Bob)

switch bobMode
    case 'Raw'
        for i = 1:nFrames
            tmp = readFrame(inObj);
            thisFrame = rgb2gray(tmp);
            oddFields = thisFrame(1:2:end,:);
            evenFields = thisFrame(2:2:end,:);
            % shift the even lines to avoid "jumping" from frame to frame. (i.e
            % align the two fields)
            evenFields = cat(1,zeros(1,size(evenFields,2),'like',evenFields), evenFields(1:end-1,:));
            writeVideo(Bob,oddFields);
            writeVideo(Bob,evenFields);
            if ~mod(i,10);progBar(i);end
        end
        
    case 'Zero'
        for i = 1:nFrames
            tmp = readFrame(inObj);
            thisFrame = rgb2gray(tmp);
            oddFields = thisFrame(1:2:end,:);
            evenFields = thisFrame(2:2:end,:);
            % put zero rows in
            m = 1;
            k = 1;
            n = size(oddFields);
            oddFields = reshape([reshape(oddFields,m,[]);zeros(k,n(1)/m*n(2))],[],n(2));
            evenFields = reshape([reshape(evenFields,m,[]);zeros(k,n(1)/m*n(2))],[],n(2));
            evenFields = cat(1,zeros(1,size(evenFields,2),'like',evenFields), evenFields(1:end-1,:));
            writeVideo(Bob,oddFields)
            writeVideo(Bob,evenFields)
            if ~mod(i,10);progBar(i);end
        end
        
    case 'Double'
        for i = 1:nFrames
            tmp = readFrame(inObj);
            thisFrame = rgb2gray(tmp);
            oddFields = thisFrame(1:2:end,:);
            evenFields = thisFrame(2:2:end,:);
            % duplicate each row
            oddFields = repelem(oddFields, 2, 1);
            evenFields = repelem(evenFields, 2, 1);
            evenFields = cat(1,zeros(1,size(evenFields,2),'like',evenFields), evenFields(1:end-1,:));
            writeVideo(Bob,oddFields)
            writeVideo(Bob,evenFields)
            if ~mod(i,10);progBar(i);end
        end
        
    case 'Mean'
        for i = 1:nFrames
            tmp             = readFrame(inObj);
            thisFrame       = rgb2gray(tmp);
            oddFields = thisFrame(1:2:end,:);
            evenFields = thisFrame(2:2:end,:);
            % put means in between rows
            %oddFields
            tmp = [oddFields(1,:); ((oddFields(1,:)+oddFields(2,:))/2);oddFields(2,:)];
            for jj = 2 : size(oddFields,1)-1
                newLines = [mean([oddFields(jj,:);oddFields(jj+1,:)],1);oddFields(jj+1,:)];
                tmp = cat(1,tmp,newLines);
            end
            oddFields = cat(1,tmp,oddFields(end,:));
            clear tmp
            clear newLines
            %evenFields
            tmp = [evenFields(1,:); ((evenFields(1,:)+evenFields(2,:))./2);evenFields(2,:)];
            for jj = 2 : size(evenFields,1)-1
                newLines = [mean([evenFields(jj,:);evenFields(jj+1,:)],1);evenFields(jj+1,:)];
                tmp = cat(1,tmp,newLines);
            end
            evenFields = cat(1,evenFields(1,:),tmp);
            clear tmp
            clear newLines
            writeVideo(Bob,oddFields)
            writeVideo(Bob,evenFields)
            if ~mod(i,10);progBar(i);end
        end
end
close (Bob)