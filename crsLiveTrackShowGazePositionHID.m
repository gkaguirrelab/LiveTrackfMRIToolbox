function crsLiveTrackShowGazePositionHID(deviceNumber, CalMat, Rpc, viewDist, screenSize, NoOfGlints, Window1ID, Window2ID)

%% setup

img{1} = imread('TeapotTexture.jpg');
img{2} = imread('konijntjes1024x768.jpg');

% set default image ID
curimg = 1;

% The diameter of the fixation point (in degrees)
degFix = 1.2;

% set number of samples to show
buf = 6; 

% control monito view scale
cnrViewScale = 0.25; % show a quarter size window of stimulus on control monitor

% draw gaze point in stimulus window
drawGazeInStimWin = true;

%% calculate screen specs

% get the resolution of the stimulus monitor
Res=Screen('Resolution', Window2ID);

% get the resolution of the control monitor 
Res2=Screen('Resolution', Window1ID);

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


%% open PTB windows

% Prepare psychToolbox configuration
PsychImaging('PrepareConfiguration');

% open a full screen window with grey background on stimulus monitor
w = PsychImaging('OpenWindow', Window2ID, 128);

% show stimulus (image)
tex = Screen('MakeTexture', w, img{curimg});
Screen('DrawTexture', w, tex, [], [0 0 Res.width Res.height]);
Screen('Flip', w);

% open a small screen on the controller monitor (primary monitor, ID=0)
winRes=[Res.width*cnrViewScale Res.height*cnrViewScale];
[w2, w2rect] = Screen('OpenWindow', Window1ID, 0, [Res2.width/2-winRes(1)/2 Res2.height/2-winRes(2)/2 Res2.width/2+winRes(1)/2 Res2.height/2+winRes(2)/2]);
Screen('TextSize',w2, 10);

% show stimulus (image) - on control monitor
tex2 = Screen('MakeTexture', w2, img{curimg});
Screen('DrawTexture', w2, tex2, [], w2rect);
Screen('Flip', w2);

% start LiveTrack Raw data
crsLiveTrackHIDcomm(deviceNumber,'begin');

pause(0.1);

getOffset = false;
xO=0; yO=0;
gzLocshis=nan(2,buf);
while true
        % get a packet (two samples) of raw data
        R = crsLiveTrackHIDcomm(deviceNumber,'continue-returnlast');

        % calibrate the raw data
        Rcal = calibrateData(R,CalMat,Rpc,NoOfGlints);
        % put the two samples in the buffer. S2 is the most recent sample
        gzLocshis = [Rcal.S2(1:2)' Rcal.S1(1:2)' gzLocshis(1:2,1:buf-2)];

        if getOffset,
            xO = Res.width/2-round(mean(gzLocshis(1,:))/pixSize+Res.width/2);
            yO = Res.height/2-round(mean(gzLocshis(2,:))/pixSize+Res.height/2);
            getOffset = false;
        end
        
        tgtLocs(1,:) = round(mean(gzLocshis(1,:))/pixSize+Res.width/2)+xO;
        tgtLocs(2,:) = round(mean(gzLocshis(2,:))/pixSize+Res.height/2)+yO;
        tgtLocs2 = tgtLocs.*cnrViewScale;

        % stimilus window
        if drawGazeInStimWin,
            Screen('FillOval', w, 255, round([tgtLocs(1,1)-fixRad...
                    tgtLocs(2,1)-fixRad tgtLocs(1,1)+fixRad tgtLocs(2,1)+fixRad]));
        end
        % control window
        DrawFormattedText(w2,['Press (-) to adjust offset. Press (+) to change image. TargetX: '...
                 ,num2str(tgtLocs2(1,1)),'  TargetY: ',num2str(tgtLocs2(2,1))],0, 30, [255, 255, 255, 255]);
        Screen('FillOval', w2, 255, round([tgtLocs2(1,1)-fixRad...
                tgtLocs2(2,1)-fixRad tgtLocs2(1,1)+fixRad tgtLocs2(2,1)+fixRad]));

    if R.S1Tracked && R.S2Tracked,
        col = [0 255 0];
    else
        col = [255 0 0];
    end
    
    DrawFormattedText(w2, [num2str(R.S2PupilX),' ',num2str(R.S2PupilY)],20, 0, [255, 255, 255, 255]);
    Screen('FillOval', w2, col,[0 0 20 20]);
    Screen('Flip', w);
    Screen('Flip', w2);
    Screen('DrawTexture', w, tex, [], [0 0 Res.width Res.height]);
    Screen('DrawTexture', w2, tex2, [], w2rect);

    [keyIsDown,secs,keyCode]=KbCheck;
    if keyIsDown,
        if keyCode(KbName('-')) % get offset
            disp('minus(-) pressed for getting offset');
            getOffset = true;
            Screen('Flip', w);
            DrawFormattedText(w,'Look at the dot','center', 'center', [255, 255, 255, 255]);
            Screen('Flip', w);
            pause(1);
        end
        if keyCode(KbName('+')) % cycle picture
            disp('plus(+) pressed for changing picture');
            if length(img)==curimg,
                curimg=1;
            else
                curimg=curimg+1;
            end
            tex = Screen('MakeTexture', w, img{curimg});
            Screen('DrawTexture', w, tex);
            tex2 = Screen('MakeTexture', w, img2{curimg});
            Screen('DrawTexture', w2, tex2);
            pause(0.1);
        end
        if keyCode(KbName('Esc'))
            crsLiveTrackHIDcomm(deviceNumber,'end');
%             LiveTrackHIDstop(deviceNumber);
            Screen('CloseAll');
            disp('Esc pressed');
            error('Esc pressed');
        end
    end
    
    if getOffset,
            Screen('Flip', w);
            Screen('FillOval', w, 255, round([Res.width/2-fixRad...
            Res.height/2-fixRad Res.width/2+fixRad Res.height/2+fixRad]));
            Screen('Flip', w);
            t0=cputime;
            while cputime-t0<1,% pause for 1 sec
                R = crsLiveTrackHIDcomm(deviceNumber,'continue-returnlast');
            end
    end

end


    function Rcal = calibrateData(R,CalMat,Rpc,NoOfGlints)
        
        if R.S1Tracked,
            if NoOfGlints==2,
                glint = [mean([R.S1Glint1X R.S1Glint2X]) mean([R.S1Glint1Y R.S1Glint2Y])];
            elseif NoOfGlints==1,
                glint = [R.S1Glint1X R.S1Glint1Y];
            else 
                error('NoOfGlints must be 1 or 2');
            end
            pupil = [R.S1PupilX R.S1PupilY];
            Rcal.S1 = crsLiveTrackCalibrateRawData(CalMat, Rpc, pupil, glint);
        else
            Rcal.S1 = NaN(1,3);
        end
        
        if R.S2Tracked,
            if NoOfGlints==2,
                glint = [mean([R.S2Glint1X R.S2Glint2X]) mean([R.S2Glint1Y R.S2Glint2Y])];
            elseif NoOfGlints==1,
                glint = [R.S2Glint1X R.S2Glint1Y];
            else 
                error('NoOfGlints must be 1 or 2');
            end
            pupil = [R.S2PupilX R.S2PupilY];
            Rcal.S2 = crsLiveTrackCalibrateRawData(CalMat, Rpc, pupil, glint);
        else
            Rcal.S2 = NaN(1,3);
        end
        
    end

end