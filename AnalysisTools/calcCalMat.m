function [calMat] = calcCalMat(params)

% Calculates the calibration matrix need to determine gaze location using
% eye tracking data
%
%   Usage:
%       calMat = calcCalMat(params)
%
%   Inputs:
%       params.pupil.X      - vector of pupil X coordinates (pixels)
%       params.pupil.Y      - vector of pupil Y coordinates (pixels)
%       params.glint.X      - vector of glint X coordinates (pixels)
%       params.glint.Y      - vector of glint Y coordinates (pixels)
%       params.targets.X    - vector of target X coordinates (pixels)
%       params.targets.Y    - vector of target Y coordinates (pixels)
%       params.viewDist     - viewing distance (mm)
%       params.rpc          - adjustment parameter (see 'calcRpc')
%
%   Output:
%       calMat              - 4 x 4 transformation matrix
%
%   Written by Andrew S Bock Oct 2016

%% initialize the matrx
X = [...
    1 0 0 0 ...
    0 1 0 0 ...
    0 0 0 0 ...
    0 0 0 1 ...
    ];
%% Loop through calls to fminsearch, changing tolerance
for i=1:20
    options = optimset('Display','off','MaxFunEvals', 10000,...
        'MaxIter', 10000, 'TolX',10^(-i/2),'TolFun',10^(-i/2));
    [X, f] = fminsearch(@(param) ...
        errfun(param,params.pupil,params.glint,params.targets,params.viewDist,params.rpc),...
        X, options);
    disp(['RSS error: ',num2str(f)])
end
%% make the calibration matrix
calMat = [X(1:4); X(5:8); X(9:12); X(13:16)];

%% error function
function errtot = errfun(param, pupil, glint, targets, viewDist, rpc)

err = nan(1,length(targets(:,1)));
CalMatrix = [param(1:4); param(5:8); param(9:12); param(13:16)];

% minimize error for each target
for i = 1:length(targets.X)
    pX = pupil.X(i);
    pY = pupil.Y(i);
    gX = glint.X(i);
    gY = glint.Y(i);
    x = targets.X(i);
    y = targets.Y(i);
    z = viewDist;
    
    aXYZW = CalMatrix * [(pX-gX)/rpc; (pY-gY)/rpc; (1 - sqrt(((pX-gX)/rpc)^2 + ((pY-gY)/rpc)^2)); 1];
    oXYZW = [x; y; z; 1];
    
    errXYZ = (aXYZW(1:3)/aXYZW(4)) - (oXYZW(1:3)/oXYZW(4));
    err(i) = sum(errXYZ.^2);
end
errtot = sum(err.^2);