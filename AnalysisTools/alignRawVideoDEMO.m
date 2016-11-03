%% Align raw tracking data to Report data

% This script aims to robustly align the RawTracking data to the TTL onset
% information provided in the LiveTrack Report.

% The LiveTrack system returns information about pupil size and position,
% gaze position (60 Hz) and TTL onset (30Hz) in a Report struct. The eye
% tracking data is not as accurate as we'd like to be, so we use a
% custom tracking routine to analyze the hi-res tracking video (raw video)
% acquired concurrently with the LiveTrack data. While the data
% obtained from the raw video (raw tracking) is much more accurate, it does
% not contain information about the TTL onset, and can't be directly synced
% to the TR timing.

% A property of the data acquisition system is that the raw video recording
% starts with a certain delay with respect to the Report recording. To
% align TTL information to the raw tracking data we need to calculate the
% data stream delay.

% We cannot rely on the timestamp provided by PsychToolbox for each field
% of the Report (i.e. frame) as an absolute time reference because it is
% assigned when the data is written in the variable, rather then when it is
% actually acquired by the device.

% We instead look at the signals resulting from the same measurement on the
% two data streams and make use of cross correlation (Signal Processing
% Toolbox) to align them and calculate the data stream delay.


%% Load data to align
clear all
close all
clc

% load LiveTrack Report
LiveTrack = load('/Users/giulia/Dropbox-Aguirre-Brainard-Lab/TOME_data/session1_restAndStructure/TOME_3001/081916/EyeTracking/rfMRI_REST_AP_run01_report.mat');
% load raw tracking data
RawTrack = load('/Users/giulia/Dropbox-Aguirre-Brainard-Lab/eyeTrackingVideos/TOME_3001-rfMRI_REST_AP_run01.mat');

%% Perform a sanity check on the LiveTrack Report
% check if the frameCount is progressive (i.e. no frame was skipped during
% data writing)
frameCountDiff = diff([LiveTrack.Report.frameCount]);
% note that there could be a frame count reset at the beginning, so it is
% ok if the frameCountDiff "jumps" once. If it jumps more, it is most
% likely an undesired skip.
frameCountJumps = diff(frameCountDiff);
skips = find(frameCountJumps);
if length(skips)>1
    warning('Frame Count is not progressive. Check current LiveTrack Report for integrity')
end

% further sanity checks for fMRI runs:

% verify that the correct amount of TTLs has been recorded
[TTLPulses] = CountTTLPulses (LiveTrack.Report);

% verify that the TTLs are correctly spaced, assuming that the acquisition
% rate is 30 Hz


%% Choose a reference signal to align data
% We need to choose the most precise LiveTrack measurement to help the
% aligning accuracy. For now, we use the X position of the glint by
% default. 
% POSSIBLE FUTURE DEV: compare each couple of signals, rate their
% similarity and use the 2 most similar signals as reference.

% Raw Track signal (for now, it is a 30 Hz signal)
RTsignal = RawTrack.glint.XY(2,:);

% Live Track signal.
LTsignal = ([LiveTrack.Report.Glint1CameraY_Ch01] + [LiveTrack.Report.Glint1CameraY_Ch02]) ./2;
% since Raw tracking is done at 30 Hz, we average the data coming from
% the two LiveTrack channels for each frame. 


%% Plot first 1000 frames of the X glint position (this is just for visual inspection)
% first we remove the signal drops from LTsignal
LTsignal(LTsignal<100) = NaN;

figure()
plot(RTsignal(1:1000))
hold on
plot(LTsignal(1:1000))
grid on
ylabel('X position of the glint (different units)')
xlabel('Frames')
legend ('RawTrack', 'LiveTrack')
title('Reference signal comparison')
% note that the Raw Track signal development preceeds the LiveTrack's. This
% is coherent with the fact that the Raw Video acquisition starts later
% than the LiveTrack Report (i.e. it doesn't have some of the early frames
% that the Report has). We need to pre-pad the RTsignal to align it with
% LTsignal.

%% Cross correlate the signals to compute the delay
% cross correlation doesn't work with NaNs, so we change them to zeros
RTsignal(isnan(RTsignal)) = 0 ;
LTsignal(isnan(LTsignal)) = 0 ;

% calculate cross correlation and also return the lag array
[r,lag] = xcorr(LTsignal,RTsignal);

% when cross correlation of the signals is max the lag equals the delay
[~,I] = max(abs(r));
delay = lag(I); % unit = [number of samples]

% we can now pre-pad the RTsignal to shift it
RTaligned = padarray(RTsignal,[0,delay],'pre');

% put back the NaNs
RTsignal(RTsignal==0) = NaN;
RTaligned(RTaligned==0) = NaN;
LTsignal(LTsignal==0) = NaN;


%% plot the first 1000 samples of the signals again to show that there is no more delay
figure()
plot(RTaligned)
hold on
plot(LTsignal)
grid on
ylabel('X position of the glint (different units)')
xlabel('Frames')
legend ('RawTrack aligned', 'LiveTrack')
title(['Aligned signals (Raw Video delay = ' num2str(delay) ' frames)']);

%% now plot full signals normalized by resolution
% this is to show more clearly that the signals have been realigned

% define signals resolutions (in pixels)
RTres = [400 300]; % resolution of the raw video
LTres = [320 240]; % resolution of the LiveTrack tracking

% normalize the signals according to their native resolution
RTSnormX = RTsignal / RTres(1);
RTAnormX = RTaligned / RTres(1);
LTSnormX = LTsignal / LTres(1);

figure()
subplot(2,1,1)
plot(RTSnormX)
hold on
plot(LTSnormX)
grid on
ylabel('Normalized X position of the glint')
xlabel('Frames')
legend ('RawTrack', 'LiveTrack')
title ('Normalized signals before alignment')

subplot(2,1,2)
plot(RTAnormX)
hold on
plot(LTSnormX)
grid on
ylabel('Normalized X position of the glint')
xlabel('Frames')
legend ('RawTrack', 'LiveTrack')
title(['Normalized signals after alignment (Raw Video delay = ' num2str(delay) ' frames)'])