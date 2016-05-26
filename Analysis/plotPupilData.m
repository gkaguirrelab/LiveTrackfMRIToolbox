function plotPupilData (matfile,condition)

if ~exist('condition', 'var')
    condition = 'pupilflag';
end

load(matfile);

Report = [params.Report];

%discard pre TTL data
TTLs = find ([Report.Digital_IO1]);
switch condition
    case 'pupilFlag' %discard samples where the PupilTracked flag is false
        figure
        
        for pp = 1:length(Report)
            if Report(pp).PupilTracked == 1 & pp > TTLs(1)
                pupilWidth(pp) = Report(pp).LeftPupilWidth;
            else
                pupilWidth(pp) = NaN;
            end
        end
        plot (pupilWidth);
        
        hold on
        for pp = 1:length(Report)
            if Report(pp).PupilTracked == 1 & pp > TTLs(1)
                pupilHeight(pp) = Report(pp).LeftPupilHeight;
            else
                pupilHeight(pp) = NaN;
            end
        end
        plot (pupilHeight);
        title ('Left Pupil data (in camera units)')
        legend ('Pupil width', 'Pupil heigth');
        xlabel ('Sample number')
        
        figure
        for pp = 1:length(Report)
            pupilarea(pp) = (pi/4)*pupilWidth(pp)*pupilHeight(pp);
        end
        plot (pupilarea);
        title ('Left Pupil area (in camera units)')
        xlabel ('Sample number')
        
        figure
        
        for pp = 1:length(Report)
            if Report(pp).PupilTracked == 1 & pp > TTLs(1)
                pupilX(pp) = Report(pp).LeftPupilCameraX;
            else
                pupilX(pp) = NaN;
            end
        end
        plot (pupilX)
        hold on
        for pp = 1:length(Report)
            if Report(pp).PupilTracked == 1 & pp > TTLs(1)
                pupilY(pp) = Report(pp).LeftPupilCameraY;
            else
                pupilY(pp) = NaN;
            end
        end
        plot (pupilY)
        legend ('Pupil X', 'Pupil Y');
        title ('Left Pupil positions (in camera units)')
        xlabel ('Sample number')
        
        
        figure
        plot (pupilX, pupilY, '*')
        title ('Left Pupil x-Y position (in camera units)')
        
        
    case 'TTLnoFlag' % include all samples regadless of the Tracking Flag
        figure
        
        for pp = 1:length(Report)
            if pp > TTLs(1)
                pupilWidth(pp) = Report(pp).LeftPupilWidth;
            else
                pupilWidth(pp) = NaN;
            end
        end
        plot (pupilWidth);
        
        hold on
        for pp = 1:length(Report)
            if pp > TTLs(1)
                pupilHeight(pp) = Report(pp).LeftPupilHeight;
            else
                pupilHeight(pp) = NaN;
            end
        end
        plot (pupilHeight);
        title ('Left Pupil data (in camera units)')
        legend ('Pupil width', 'Pupil heigth');
        xlabel ('Sample number')
        
        figure
        for pp = 1:length(Report)
            pupilarea(pp) = (pi/4)*pupilWidth(pp)*pupilHeight(pp);
        end
        plot (pupilarea);
        title ('Left Pupil area (in camera units)')
        xlabel ('Sample number')
        
        figure
        
        for pp = 1:length(Report)
            if pp > TTLs(1)
                pupilX(pp) = Report(pp).LeftPupilCameraX;
            else
                pupilX(pp) = NaN;
            end
        end
        plot (pupilX)
        hold on
        for pp = 1:length(Report)
            if  pp > TTLs(1)
                pupilY(pp) = Report(pp).LeftPupilCameraY;
            else
                pupilY(pp) = NaN;
            end
        end
        plot (pupilY)
        legend ('Pupil X', 'Pupil Y');
        title ('Left Pupil positions (in camera units)')
        xlabel ('Sample number')
        
        
        figure
        plot (pupilX, pupilY, '*')
        title ('Left Pupil x-Y position (in camera units)')
        
    case 'noTTL'
        
        figure
        
        for pp = 1:length(Report)
            
            pupilWidth(pp) = Report(pp).LeftPupilWidth;
            
            %             pupilWidth(pp) = NaN;
            
        end
        plot (pupilWidth);
        
        hold on
        for pp = 1:length(Report)
            %         if Report(pp).PupilTracked == 1
            pupilHeight(pp) = Report(pp).LeftPupilHeight;
            %         else
            %             pupilHeight(pp) = NaN;
            %         end
        end
        plot (pupilHeight);
        title ('Left Pupil data (in camera units)')
        legend ('Pupil width', 'Pupil heigth');
        xlabel ('Sample number')
        
        figure
        for pp = 1:length(Report)
            pupilarea(pp) = (pi/4)*pupilWidth(pp)*pupilHeight(pp);
        end
        plot (pupilarea);
        title ('Left Pupil area (in camera units)')
        xlabel ('Sample number')
        
        figure
        
        for pp = 1:length(Report)
            if Report(pp).PupilTracked == 1
                pupilX(pp) = Report(pp).LeftPupilCameraX;
            else
                pupilX(pp) = NaN;
            end
        end
        plot (pupilX)
        hold on
        for pp = 1:length(Report)
            if  Report(pp).PupilTracked == 1
                pupilY(pp) = Report(pp).LeftPupilCameraY;
            else
                pupilY(pp) = NaN;
            end
        end
        plot (pupilY)
        legend ('Pupil X', 'Pupil Y');
        title ('Left Pupil positions (in camera units)')
        xlabel ('Sample number')
        
        
        figure
        plot (pupilX, pupilY, '*')
        title ('Left Pupil x-Y position (in camera units)')
end


