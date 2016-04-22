function [Report] = GetDataVideo (TRnum)

% Usage
% savePath = '/Users/giulia/Desktop/TEST';
% TRnum = Inf OR num of TRs

%% set saving path and names
formatOut = 'mmddyy_HHMMSS';
timestamp = datestr((datetime('now')),formatOut);
vidName = ['LiveTrackVIDEO_' timestamp];
reportName = ['LiveTrackREPORT_' timestamp '.mat'];

feature('jit',0)
feature('accel',0)


%% find  Livetrack
% data collection
[deviceNumber, type] = crsLiveTrackGetHIDdeviceNumber;
% video recording
vid = videoinput('macvideo', 1, 'YUY2_320x240'); %'YCbCr422_1280x720') %;
src = getselectedsource(vid);

%% initialize
fprintf('\n Press spacebar to initialize LiveTrack.');
pause;
%video recording
vid.FramesPerTrigger = Inf;
frameRate = 30; %default fps
vid.LoggingMode = 'disk';
diskLogger = VideoWriter(fullfile('/Users/giulia/Desktop/TEST/',vidName), 'Motion JPEG AVI');
vid.DiskLogger = diskLogger;
% set manual trigger
triggerconfig(vid, 'manual') %change to appropriate trigger configuration

preview(vid);
R = LiveTrackHIDcomm(deviceNumber,'begin');
start(vid); %initialize video ob
TR = 0;
ii = 1;
jj = 1;
log = true;
fprintf('\n LiveTrack: Listening...');

%% logging

while log 
Q = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
  

if Q.Digital_IO1 == 0 && TR <=TRnum
%     ii = ii+1;     
    R1 = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
        Report (ii) = R1;
        
    elseif Q.Digital_IO1 == 1 && TR ==0
%         ii = ii+1;
        trigger(vid);
        err = PsychHID('SetReport', deviceNumber,2,0,uint8([103 zeros(1,63)]));
        R2 = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
        Report (ii) = R2;
%                 
        TR = TR+1;
        fprintf('\n TTL detected! (TR = %d)\n',TR);
    elseif Q.Digital_IO1 == 1 && TR<TRnum
%         ii = ii+1;
        R3 = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
        Report (ii) = R3;
                
%         TTLspacing(jj) = Report(ii).Digital_IO1- Report(ii -1).Digital_IO1;
%         if TTLspacing(jj) == 0
%             ii = ii+1;
%             jj = jj+1;
%             fprintf('\nartifact\n');
%         else
            TR = TR+1;
%             ii = ii+1;
            jj = jj+1;
            fprintf('\n TTL detected! (TR = %d)\n',TR);
%         end
    elseif Q.Digital_IO1 == 1 && TR == TRnum
        buff = 0;
        for buff = 1:500
            ii = ii+1;
            R4 = LiveTrackHIDcomm(deviceNumber,'continue-returnlast');
            Report (ii) = R4;
                
                buff=buff+1;
        end
        log = false;
    
end
% ii = ii+1; 
end

stop(vid);
stoppreview(vid);

LiveTrackHIDcomm(deviceNumber,'end');
closepreview(vid);
save((fullfile('/Users/giulia/Desktop/TEST/',reportName)), 'Report');
fprintf('Matfile and video saved.\n');

