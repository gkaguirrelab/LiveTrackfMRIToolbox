function [targets,dotTimes] = show9Targets(viewDist, screenSize, Window2ID, FixTime)
% no livetrack is involved in this function!

%% Set default colors for background and dots

bkground = [255 255 255]; % background color (white)
dotColor = [0 0 0]; % dot color (black)

%% Fixation parameters
if ~exist ('FixTime', 'var')
    FixTime = 3;
end

% Define the diameter of the fixation points (in degrees)
degFix = 0.2;

% calibration target locations in screen coordinates (x-pos=right,
% y-pos=down)
% calTargets = [-7 -7;7 -7;7 7;-7 7;0 0]; %UL, UR, DR, DL, Ctr (5 points)
calTargets = [-7 -7;0 -7;7 -7;-7 0;0 0;7 0;-7 7;0 7;7 7]; % (9 points)

% randomize order of targets:
calTargets = calTargets(randperm(size(calTargets,1)),:);


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

%% open PTB windows and display dots

% Prepare psychToolbox configuration
PsychImaging('PrepareConfiguration');

% open a full screen window with grey background on stimulus monitor

w = PsychImaging('OpenWindow', Window2ID, bkground);


for i = 1:size(calTargets,1)
    % draw new fixation point
    Screen('FillOval', w, dotColor, round([tgtLocs(i,1)-fixRad...
        tgtLocs(i,2)-fixRad tgtLocs(i,1)+fixRad tgtLocs(i,2)+fixRad]));
    Screen('Flip', w);    
    dotTimes(i) = GetSecs;
    pause (FixTime)
    targets(i,:) = calTargets(i,:)*degPerMM;
end
dotTimes(i+1) = GetSecs;

Screen('CloseAll');

