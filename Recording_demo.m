%% Find camera
im_info = imaqhwinfo;
cameraID = im_info.InstalledAdaptors;

vid = videoinput(cameraID{1}); %change {1} according to LiveTrack position in the array
%% set parameters

set(vid, 'FramesPerTrigger', Inf);
set(vid, 'ReturnedColorspace', 'rgb');
% vid.FrameRate =30;
vid.FrameGrabInterval = 1;  % distance between captured frames 
start(vid)

aviObject = VideoWriter('myVideo.avi');   % Create a new AVI file
for iFrame = 1:100                    % Capture 100 frames
  % ...
  % You would capture a single image I from your webcam here
  % ...

  I=getsnapshot(vid);
%imshow(I);
  F = im2frame(I);                    % Convert I to a movie frame
  aviObject = addframe(aviObject,F);  % Add the frame to the AVI file
end
aviObject = close(aviObject);         % Close the AVI file
stop(vid);