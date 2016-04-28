function [CalMat, f] = crsLiveTrackCalculateCalibrationMatrix(pupil, glint, targets, viewDist, Rpc)

X = [...
    1 0 0 0 ...
    0 1 0 0 ...
    0 0 0 0 ...
    0 0 0 1 ...
    ];

% exclude nans
pupil = pupil(~isnan(pupil(:,1)),:);
glint = glint(~isnan(glint(:,1)),:);
targets = targets(~isnan(targets(:,1)),:);



tol = [1e-1 1e-4 1e-6 1e-8 1e-8 1e-8 1e-8];
for i=1:7,
    options = optimset('Display','off','MaxFunEvals', 10000,...
        'MaxIter', 10000, 'TolX', tol(i),'TolFun',tol(i));
    [X, f] = fminsearch(@(param) errfun(param, pupil, glint, targets, viewDist, Rpc), X, options);
    disp(['RSS error: ',num2str(f)])
end

% make the calibration matrix
CalMat = [X(1:4); X(5:8); X(9:12); X(13:16)];

function errtot = errfun(param, pupil, glint, targets, viewDist, Rpc)

err = nan(1,length(targets(:,1)));
CalMatrix = [param(1:4); param(5:8); param(9:12); param(13:16)];

% minimize error for each target
for i = 1:length(targets(:,1))
    pX = pupil(i,1);
    pY = pupil(i,2);
    gX = glint(i,1);
    gY = glint(i,2);
    x = targets(i,1);
    y = targets(i,2);
    z = viewDist;

    aXYZW = CalMatrix * [(pX-gX)/Rpc; (pY-gY)/Rpc; (1 - sqrt(((pX-gX)/Rpc)^2 + ((pY-gY)/Rpc)^2)); 1];
    oXYZW = [x; y; z; 1];

    errXYZ = (aXYZW(1:3)/aXYZW(4)) - (oXYZW(1:3)/oXYZW(4));
    err(i) = sum(errXYZ.^2);   
end
errtot = sum(err.^2);

