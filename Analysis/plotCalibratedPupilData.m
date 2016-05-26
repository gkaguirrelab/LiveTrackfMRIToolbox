function plotCalibratedPupilData (matfileData,matfileCalibration, condition)

if ~exist('condition', 'var')
    condition = 'pupilFlag';
end

%extract calibration factors
load(matfileCalibration);
Wfactor = params.cameraUnitsToMmWidthMean;
Hfactor = params.cameraUnitsToMmHeightMean;

% convert raw data to calibrated data
[ReportCalibrated] = pixel2mm(matfileData, Wfactor, Hfactor);

%discard pre TTL data
TTLs = find ([ReportCalibrated.Digital_IO1]);

%plot data
switch condition
    case 'pupilFlag' %discard samples where the PupilTracked flag is false
        figure
        
        for pp = 1:length(ReportCalibrated)
            if ReportCalibrated(pp).PupilTracked == 1 & pp > TTLs(1)
                pupilWidth(pp) = ReportCalibrated(pp).LeftPupilWidth;
            else
                pupilWidth(pp) = NaN;
            end
        end
        plot (pupilWidth);
        
        hold on
        for pp = 1:length(ReportCalibrated)
            if ReportCalibrated(pp).PupilTracked == 1 & pp > TTLs(1)
                pupilHeight(pp) = ReportCalibrated(pp).LeftPupilHeight;
            else
                pupilHeight(pp) = NaN;
            end
        end
        plot (pupilHeight);
        title ('Left Pupil data (in mm)')
        legend ('Pupil width', 'Pupil heigth');
        xlabel ('Sample number')
        ylabel ('Length in mm')
        
        figure
        for pp = 1:length(ReportCalibrated)
            pupilarea(pp) = (pi/4)*pupilWidth(pp)*pupilHeight(pp);
        end
        plot (pupilarea);
        title ('Left Pupil area (in sqmm)')
        xlabel ('Sample number')
        ylabel ('Area in square mm')
        
        case 'TTLnoFlag' % include all samples regadless of the Tracking Flag
        figure
        
        for pp = 1:length(ReportCalibrated)
            if pp > TTLs(1)
                pupilWidth(pp) = ReportCalibrated(pp).LeftPupilWidth;
            else
                pupilWidth(pp) = NaN;
            end
        end
        plot (pupilWidth);
        
        hold on
        for pp = 1:length(ReportCalibrated)
            if pp > TTLs(1)
                pupilHeight(pp) = ReportCalibrated(pp).LeftPupilHeight;
            else
                pupilHeight(pp) = NaN;
            end
        end
        plot (pupilHeight);
        title ('Left Pupil data (in mm)')
        legend ('Pupil width', 'Pupil heigth');
        xlabel ('Sample number')
        ylabel ('Length in mm')
        
        figure
        for pp = 1:length(ReportCalibrated)
            pupilarea(pp) = (pi/4)*pupilWidth(pp)*pupilHeight(pp);
        end
        plot (pupilarea);
        title ('Left Pupil area (in mm)')
        xlabel ('Sample number')
        ylabel ('Area in square mm')
end