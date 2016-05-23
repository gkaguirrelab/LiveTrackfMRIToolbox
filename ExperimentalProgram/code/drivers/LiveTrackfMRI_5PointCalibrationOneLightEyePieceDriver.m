function params = LiveTrackfMRI_5PointCalibrationOneLightEyePieceDriver(expt);

%% IR Camera setup
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
if ~isempty(strfind(type,'AV')),
    NoOfGlints = 1;% one for LiveTrack for fMRI
    disp('Device type "LiveTrack AV" found!');
elseif ~isempty(strfind(type,'FM')),
	NoOfGlints = 2;% or two for LiveTrack-FM
	disp('Device type "LiveTrack FM" found!');
else
    error('Must be LiveTrack FM or LiveTrack AV device type!');
end

%% user input

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
targetEccInDeg = 32;
calTargets = [0 -targetEccInDeg ; targetEccInDeg 0 ; 0 targetEccInDeg ; -targetEccInDeg 0 ; 0 0]; % 12 o'clock, 3 o'clock, 6 o'clock, 9 o'clock ; center
calTargetLabels = {'12 o''clock' '3 o''clock' '6 o''clock' '9 o''clock' 'Center'};

% time before getting data from fixation (to ignore initial saccade)
waitTimeForFix = 1;

%% target location in pixels
% start LiveTrack Raw data streaming
crsLiveTrackHIDcomm(deviceNumber,'begin');
% LiveTrackHIDstartRaw(deviceNumber);
pause(0.1);

for i = 1:size(calTargets,1)

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
            Speak('Sample valid');
        else
            % show red dot in corner if sample if invalid
            Speak('Sample invalid');
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
        targets(i,:) = calTargets(i,:);
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
    
    
    
    params.pupil = pupil
    params.glint = glint;
    params.targets = target;
    params.Rpc = Rpc;
    
end