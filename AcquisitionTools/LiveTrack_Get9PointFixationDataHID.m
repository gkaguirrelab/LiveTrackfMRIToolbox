function [pupil, glint, targets, Rpc] = LiveTrack_Get9PointFixationDataHID(deviceNumber, viewDist, screenSize, NoOfGlints, Window1ID, Window2ID)

%% Set default colors

bkground = [255 255 255]; % background color (white)
dotColor = [0 0 0]; % dot color (black)

%% Fixation parameters

% Define the diameter of the fixation points (in degrees)
degFix = 0.2;

% define the amount of samples required for each fixation - decrease to
% make calibration "easier"/faster
fixDur = 25;

% fixation window in camera units (all fixDur samples must be within this
% window) - increase to make calibration "easier"
fixWindow = 2.5;

% time limit for aquiring fixation (in seconds) - skip fixation if not
% aquired after this time
maxFixTime = 20;

% calibration target locations in screen coordinates (x-pos=right,
% y-pos=down)
% calTargets = [-7 -7;7 -7;7 7;-7 7;0 0]; %UL, UR, DR, DL, Ctr (5 points)
calTargets = [-7 -7;0 -7;7 -7;-7 0;0 0;7 0;-7 7;0 7;7 7]; % (9 points)


% randomize order of targets:
calTargets = calTargets(randperm(size(calTargets,1)),:);

% time before getting data from fixation (to ignore initial saccade)
waitTimeForFix = 1;


%% calculate screen specs

% get the resolution of the stimulus monitor
Res=Screen('Resolution', Window2ID);

% calculate screen width and height (in mm) - assuming square pixels
screenW = sind(atand(Res.width/Res.height))*screenSize*25.4;
screenH = sind(atand(Res.height/Res.width))*screenSize*25.4;

% calculate pixel size (in mm) assuming square pixels
pixSize = screenW/Res.width;

% mm per degree
degPerMM = tand(1)*viewDist;

% calculate pixels per degree
pixPerDeg = degPerMM/pixSize;

% The radius of the fixation points (in pixels)
fixRad = degFix*pixPerDeg/2;

% target location in pixels
cnrTarget = [round(Res.width/2) round(Res.height/2)];
tgtLocs(:,1) = round(calTargets(:,1)*pixPerDeg+cnrTarget(1)); 
tgtLocs(:,2) = round(calTargets(:,2)*pixPerDeg+cnrTarget(2));

%% open PTB windows and start collecting data

% Prepare psychToolbox configuration
PsychImaging('PrepareConfiguration');

% open a full screen window with grey background on stimulus monitor
w = PsychImaging('OpenWindow', Window2ID, bkground);

% open a small screen on the controller monitor
winRes=[400 400];
Res=Screen('Resolution', Window1ID);
[w2, w2rect] = Screen('OpenWindow', Window1ID, 0, [Res.width/2-winRes(1)/2 Res.height/2-winRes(2)/2 Res.width/2+winRes(1)/2 Res.height/2+winRes(2)/2]);
Screen('TextSize',w2, 10);

% start LiveTrack Raw data streaming
crsLiveTrackHIDcomm(deviceNumber,'begin');
% LiveTrackHIDstartRaw(deviceNumber);
pause(0.1);

for i = 1:size(calTargets,1)
    
    % draw new fixation point
    Screen('FillOval', w, dotColor, round([tgtLocs(i,1)-fixRad...
        tgtLocs(i,2)-fixRad tgtLocs(i,1)+fixRad tgtLocs(i,2)+fixRad]));
    Screen('Flip', w);
    
    % update debug window during waitTimeForFix
    tic;
    while toc < waitTimeForFix
        R = crsLiveTrackHIDcomm(deviceNumber,'continue-returnlast');
%         R = LiveTrackHIDGetRawSample(deviceNumber,1);
        if ~isempty(R),
            showPupil(w2,R,w2rect);
        end
    end
    
    dataBuf = [];
    gotFix = 0;
    tic; % reset fixation timer 
    while ~gotFix,
        
        % redraw fixation point
        Screen('FillOval', w, dotColor, round([tgtLocs(i,1)-fixRad tgtLocs(i,2)-fixRad tgtLocs(i,1)+fixRad tgtLocs(i,2)+fixRad]));
        Screen('Flip', w);
        
        % get latest packet of data (one packet = two samples)
        R = crsLiveTrackHIDcomm(deviceNumber,'continue-returnlast');
%         R = LiveTrackHIDGetRawSample(deviceNumber,1);
        
        % save sample in buffer if valid. Use sample 2 only (most recent
        % sample)
        if R.S2Tracked,
            if size(dataBuf,1)<fixDur,
                dataBuf = [dataBuf; R];
            else
                dataBuf = [dataBuf(2:fixDur, :); R];
            end
            % show green dot in corner if sample is valid
            col = [0 255 0];
        else
            % show red dot in corner if sample if invalid
            col = [255 0 0];
        end
        
        % extract pupil and glint data from most recent sample (S2)
        if ~isempty(dataBuf)
            pX = Struct2Vect(dataBuf,'S2PupilX');
            pY = Struct2Vect(dataBuf,'S2PupilY');
            g1X = Struct2Vect(dataBuf,'S2Glint1X');
            g1Y = Struct2Vect(dataBuf,'S2Glint1Y');
            g2X = Struct2Vect(dataBuf,'S2Glint2X');
            g2Y = Struct2Vect(dataBuf,'S2Glint2Y');
            if NoOfGlints==2,
                gX = mean([g1X g2X]);
                gY = mean([g1Y g2Y]);
            elseif NoOfGlints==1
                gX = g1X;
                gY = g1Y;
            else
                error('NoOfGlints must be 1 or 2');
            end
            
            % Check if pupil-to-glint vector is changing too much
            pgDist = max([max(pX-gX)-min(pX-gX) max(pY-gY)-min(pY-gY)]);
        
            showPupil(w2,R,w2rect,col,dataBuf,fixDur,pgDist,fixWindow);
        
            if pgDist<=fixWindow,
                if size(dataBuf,1)>=fixDur
                    gotFix = 1; % good fixation aquired
                end
            else
                dataBuf = [];
            end
        end
        
        [keyIsDown,secs,keyCode]=KbCheck;
        if keyIsDown,
            if keyCode(KbName('Esc'))
                Screen('CloseAll');
                disp('Esc pressed');
                error('Esc pressed');
            end
        end
        
        if toc>maxFixTime,
            gotFix = 2; % fixation timed out
            warning(['Fixation no. ',num2str(i),' timed out']);
        end

    end
    
    if gotFix==1,
        fixX = median(pX);
        fixY = median(pY);

        myPupSizX = median(Struct2Vect(dataBuf,'S2PupilW'));
        myPupSizY = median(Struct2Vect(dataBuf,'S2PupilH'));

        glint1X = median(g1X);
        glint1Y = median(g1Y);
        glint2X = median(g2X);
        glint2Y = median(g2Y);
        if NoOfGlints==2,
            glintX = mean([glint1X glint2X]);
            glintY = mean([glint1Y glint2Y]);
        elseif NoOfGlints==1,
            glintX = glint1X;
            glintY = glint1Y;
        else
            error('NoOfGlints must be 1 or 2');
        end

        dataStructAll{i} = dataBuf; % save all
        
        pupil(i,:) = [fixX fixY];
        glint(i,:) = [glintX glintY];
        targets(i,:) = calTargets(i,:)*degPerMM;
    elseif gotFix==2, % fixation timed out

        pupil(i,:) = [NaN NaN];
        glint(i,:) = [NaN NaN];
        targets(i,:) = [NaN NaN];
        
    else
        error('gotfix must be 1 or 2 at this stage')
    end 


end

% end of fixations. Stop LiveTrack
crsLiveTrackHIDcomm(deviceNumber,'end');
% LiveTrackHIDstop(deviceNumber);

Screen('CloseAll');

% Get an estimate for Rpc by using a corner target (where the subject is
% likely to not be viewing directly into the camera)
[Y,I] = max(sum(abs(targets),2));
cornert = targets(I, :);
cornerp = pupil(I, :);
cornerg = glint(I, :);
screenX=0; screenY=0;
Rpc = (sqrt((cornert(1)-screenX)^2 + (cornert(2)-screenY)^2 + viewDist^2)...
        / sqrt((cornert(1)-screenX)^2 + (cornert(2)-screenY)^2)) *...
        sqrt((cornerp(1) - cornerg(1))^2 + (cornerp(2) - cornerg(2))^2);

% function to update debug window
function showPupil(w2,R,w2rect,col,dataBuf,fixDur,pgDist,fixWindow)
    if nargin<4,
         if R.S2Tracked,
            % show green dot in corner if sample is valid
            col = [0 255 0];
        else
            % show red dot in corner if sample if invalid
            col = [255 0 0];
        end
        dataBuf=[];fixDur=100; pgDist=0;fixWindow=0;
        
    end
    
    if fixWindow>=pgDist,
        % show green bar in if deltaGaze is smaller than limit
        col2 = [0 255 0];
    else
        % show red bar in if deltaGaze is bigger than limit
        col2 = [255 0 0];
    end
        
    DrawFormattedText(w2,['deltaGaze=',num2str(pgDist)],0, 350, [255, 255, 255, 255]);
    DrawFormattedText(w2,['deltaGazeLimit=',num2str(fixWindow)],0, 360, [255, 255, 255, 255]);
    DrawFormattedText(w2,['Frame number=',num2str(R.timeStamp)],0, 320, [255, 255, 255, 255]);
    Screen('FrameRect', w2,[255 255 255],[0 w2rect(4)-10 w2rect(3)/4 w2rect(4)-6]);
    Screen('FillRect', w2, col2, [0 w2rect(4)-10 w2rect(3)*(pgDist/fixWindow)/4 w2rect(4)-6]);
    
    Screen('FrameRect', w2,[255 255 255],[0 0 320 240]+10);
    Screen('FillRect', w2, [255 255 255], [0 w2rect(4)-5 w2rect(3)*(size(dataBuf,1)/fixDur) w2rect(4)]);
    Screen('FillOval', w2, col,[w2rect(3)-10 0 w2rect(3) 10]);
    if R.S2PupilW>0 && R.S2PupilH>0,
        DrawFormattedText(w2, ['Pupil position: ',num2str(R.S2PupilX),' ',num2str(R.S2PupilY)],0, 330, [255, 255, 255, 255]);
        
        Screen('FrameOval', w2 ,[255 255 255] ,[R.S2PupilX-R.S2PupilW/2 R.S2PupilY-R.S2PupilH/2 R.S2PupilX+R.S2PupilW/2 R.S2PupilY+R.S2PupilH/2]*0.5);
    end
    if R.S2Glint1X~=0 && R.S2Glint1Y~=0,
        Screen('FillOval', w2 ,[255 255 255] ,[R.S2Glint1X-2 R.S2Glint1Y-2 R.S2Glint1X+2 R.S2Glint1Y+2]*0.5);
    end
    if R.S2Glint2X~=0 && R.S2Glint2Y~=0,  
        Screen('FillOval', w2 ,[255 255 255] ,[R.S2Glint2X-2 R.S2Glint2Y-2 R.S2Glint2X+2 R.S2Glint2Y+2]*0.5);
    end
    Screen('Flip', w2);
end

end