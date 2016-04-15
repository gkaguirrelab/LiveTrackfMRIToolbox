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