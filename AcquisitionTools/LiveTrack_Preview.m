function LiveTrack_Preview

% Use this function to adjust camera position and focus. This function
% does not save out any video.

[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
fprintf('\n Press spacebar to open the preview window.');
pause;
preview(vid);
fprintf('\n Press spacebar to end LiveTrack_preview.');
pause;
stoppreview(vid);
closepreview(vid);


% cleanup
delete(vid)
clear
close(gcf)
