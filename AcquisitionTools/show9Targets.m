function [targets,dotTimes] = show9Targets(viewDist, screenSize, Window2ID, FixTime)
% This function uses Psychtoolbox's "Screen" to present 9 Fixation dots on
% a secondary monitor. The size and position of the dots is related to the
% viewing distance and the secondary screen size, and it is the same used
% in LiveTrack_Get9PointFixationDataHID.m 
% 
% Target location and presentation times are output at the end of the
% routine.
% 
% Note that NO calibration data is collected by this function.
% 
% 
% Usage
% 
% viewDist = 1065;
% screenSize = 19;
% Window1ID = 0; 
% Window2ID = 1;
% 
% %%%% Start raw video collection here
% [targets, dotTimes] = show9Targets(viewDist, screenSize, Window2ID)
% %%%% Stop raw video collection here
% 
%% Set default colors for background and dots

bkground = [255 255 255]; % background color (white)
dotColor = [0 0 0]; % dot color (black)

%% Fixation parameters (same as those used by the LiveTrack)
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

% open a full screen window with white background on stimulus monitor
w = PsychImaging('OpenWindow', Window2ID, bkground);

% present dots
for i = 1:size(calTargets,1)
    Screen('FillOval', w, dotColor, round([tgtLocs(i,1)-fixRad...
        tgtLocs(i,2)-fixRad tgtLocs(i,1)+fixRad tgtLocs(i,2)+fixRad]));
    Screen('Flip', w);    
    dotTimes(i) = GetSecs;
    pause (FixTime)
    targets(i,:) = calTargets(i,:)*degPerMM;
end
dotTimes(i+1) = GetSecs;

Screen('CloseAll');

