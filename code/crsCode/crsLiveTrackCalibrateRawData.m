function data = crsLiveTrackCalibrateRawData(CalMat, Rpc, pupil, glint)

data = nan(length(pupil(:,1)),3);
% calibrate each sample of data
for i = 1:length(pupil(:,1))
    pX = pupil(i,1);
    pY = pupil(i,2);
    gX = glint(i,1);
    gY = glint(i,2);
   
    aXYZW = CalMat * [(pX-gX)/Rpc; (pY-gY)/Rpc; (1 - sqrt(((pX-gX)/Rpc)^2 + ((pY-gY)/Rpc)^2)); 1];
    data(i,:) = (aXYZW(1:3)/aXYZW(4))';
end