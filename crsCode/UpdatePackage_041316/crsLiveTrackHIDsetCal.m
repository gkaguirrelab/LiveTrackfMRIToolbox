function crsLiveTrackHIDsetCal(deviceNumber,RightEye,aMat,eMat,Rpc,X_singleGlintOffset,Y_singleGlintOffset)
% send calibration parameters to LiveTrack

% X = [686.896300968167,-17.5628281785336,-4.27760968536454,11.4968891118758,...
%     33.2844161516784,671.479869778359,-2.27623765047862,-103.506217008280,...
%     -115.483488292344,19.5178962506661,-230.550910254316,468.207574428349,...
%     -0.224573154768096,-0.0567403122909473,-0.560857693562705,1.03447925427547];
% 
% aMat = [X(1:4); X(5:8); X(9:12); X(13:16)];
% eMat = [    0.00000001  0       0       0;...
%             0       0.00000001  0       0;... 
%             0       0       0.00000001  0;
%             0       0       0       9999999];
%         
% Rpc = 82.9985;

if nargin<6,
    X_singleGlintOffset = 0;
    Y_singleGlintOffset = 0;    
end

if nargin<3,
    aMat = [-2.919246444803344e+15 7.018943162941563e+13 -1.598589031725037e+14 3.269469762188474e+14;
    2.089800231371030e+14 2.684058946760330e+15 4.379486245704038e+14 -9.419698422864538e+13;
    1.304294904386833e+15 -1.326297387626762e+15 1.855940866399211e+14 1.126825202180877e+15;
    2.609400941628260e+12 -2.654266828620647e+12 3.730264149784392e+11 2.251823905124515e+12];

    Rpc = 1.387624860285202e+02;

    eMat = zeros(4);
    eMat(4,4) = 1;
    eMat = eMat(:);
end

if nargin<2,
    RightEye = false;
end

if nargin<1,
    deviceNumber = crsLiveTrackGetHIDdeviceNumber;
end

aMat = aMat'; % transverse the matrix

% packet type
packetType = typecast(uint16(301), 'uint8');
packet1(1:2) = packetType;
packet2(1:2) = packetType;
packet3(1:2) = packetType;

% tag
if RightEye,
    packet1(3:4) = uint8([4 0]); % 1 (left eye) or 4 (right eye)
    packet2(3:4) = uint8([5 0]); % 2 (left eye) or 3 (right eye)
    packet3(3:4) = uint8([6 0]); % 3 (left eye) or 5 (right eye)
else
    packet1(3:4) = uint8([1 0]); % 1 (left eye) or 4 (right eye)
    packet2(3:4) = uint8([2 0]); % 2 (left eye) or 3 (right eye)
    packet3(3:4) = uint8([3 0]); % 3 (left eye) or 5 (right eye)
end

% scale (not used - using floats instead)
maxNum = max([max(aMat) max(eMat) max(Rpc)]);
scale = typecast(uint32(round(maxNum/2^32)), 'uint8');
packet1(5:8) = scale;

% A matrix
c=0;
for i = 9:4:64,
    c=c+1;
    element = typecast(single(aMat(c)), 'uint8');
    packet1(i:i+3) = element;
end
element = typecast(single(aMat(15)), 'uint8');
packet2(5:8) = element;
element = typecast(single(aMat(16)), 'uint8');
packet2(9:12) = element;

% E matrix
c=0;
for i = 13:4:64,
	c=c+1;
    element = typecast(single(eMat(c)), 'uint8');
    packet2(i:i+3) = element;
end
element = typecast(single(eMat(14)), 'uint8');
packet3(5:8) = element;
element = typecast(single(eMat(15)), 'uint8');
packet3(9:12) = element;
element = typecast(single(eMat(16)), 'uint8');
packet3(13:16) = element;

% Rpc
element = typecast(single(Rpc), 'uint8');
packet3(17:20) = element;

% X_singleGlintOffset
element = typecast(single(X_singleGlintOffset), 'uint8');
packet3(21:24) = element;

% Y_singleGlintOffset
element = typecast(single(Y_singleGlintOffset), 'uint8');
packet3(25:28) = element;

% fill the rest with zeros
packet3(29:64) = uint8(0);

% send packet 1
err = PsychHID('SetReport', deviceNumber, 2, 0, packet1);
if err.n
    fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
else
    fprintf('\nLiveTrack: Sent calibration packet 1 of 3.\n');
end

pause(0.1);

% send packet 2
err = PsychHID('SetReport', deviceNumber, 2, 0, packet2);
if err.n
    fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
else
    fprintf('\nLiveTrack: Sent calibration packet 2 of 3.\n');
end

pause(0.1);

% send packet 3
err = PsychHID('SetReport', deviceNumber, 2, 0, packet3);
if err.n
    fprintf('\nPsychHID: SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
else
    fprintf('\nLiveTrack: Sent calibration packet 3 of 3.\n');
end