function pixel2mm(matfile, Wfactor, Hfactor)


% convert camera units to mm for Width and Height

load(matfile);

ReportCalibrated = [params.Report];

for pp = 1:length(ReportCalibrated)
    ReportCalibrated(pp).LeftPupilWidth = ReportCalibrated(pp).LeftPupilWidth/Wfactor;
    ReportCalibrated(pp).LeftPupilHeight = ReportCalibrated(pp).LeftPupilHeight/Hfactor;
end

%%%% to be added: convert camera units to mm for X and Y pupil coordinates
%%%% (needs gaze calibration)