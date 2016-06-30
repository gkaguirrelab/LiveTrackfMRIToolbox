%% Set some parameters
% Identify the user
if isunix
    [~, user_name] = system('whoami') ; % exists on every unix that I know of
    % on my mac, isunix == 1
elseif ispc
    [~, user_name] = system('echo %USERDOMAIN%\%USERNAME%') ; % Not as familiar with windows,
    % found it on the net elsewhere, you might want to verify
end

% Path to local Dropbox
localDropboxDir = fullfile('/Users', strtrim(user_name), '/Dropbox (Aguirre-Brainard Lab)');
NSubjects = 4;

LMSData = {'MELA_analysis/MelanopsinMRMaxLMSCRF/HERO_asb1/HERO_asb1-MelanopsinMRMaxLMSCRF_CRF.csv' ...
    'MELA_analysis/MelanopsinMRMaxLMSCRF/HERO_aso1/HERO_aso1-MelanopsinMRMaxLMSCRF_CRF.csv' ...
    'MELA_analysis/MelanopsinMRMaxLMSCRF/HERO_gka1/HERO_gka1-MelanopsinMRMaxLMSCRF_CRF.csv' ...
    'MELA_analysis/MelanopsinMRMaxLMSCRF/HERO_mxs1/HERO_mxs1-MelanopsinMRMaxLMSCRF_CRF.csv'};

MelData = {'MELA_analysis/MelanopsinMRMaxMelCRF/HERO_asb1/HERO_asb1-MelanopsinMRMaxMelCRF_CRF.csv' ...
    'MELA_analysis/MelanopsinMRMaxMelCRF/HERO_aso1/HERO_aso1-MelanopsinMRMaxMelCRF_CRF.csv' ...
    'MELA_analysis/MelanopsinMRMaxMelCRF/HERO_gka1/HERO_gka1-MelanopsinMRMaxMelCRF_CRF.csv' ...
    'MELA_analysis/MelanopsinMRMaxMelCRF/HERO_mxs1/HERO_mxs1-MelanopsinMRMaxMelCRF_CRF.csv'};

for ss = 1:NSubjects
    CRF_LMS(:, ss) = csvread(fullfile(localDropboxDir, LMSData{ss}));
    CRF_Mel(:, ss) = csvread(fullfile(localDropboxDir, MelData{ss}));
end

crfFig = figure;
hold on;
CRF_LMS_mean = mean(CRF_LMS, 2);
CRF_Mel_mean = mean(CRF_Mel, 2);

errorbar(log10(theContrastsScaled*100), -CRF_LMS_mean, std(CRF_LMS, [], 2)/sqrt(NSubjects), '-k');
errorbar(log10(theContrastsScaled*100), -CRF_Mel_mean, std(CRF_Mel, [], 2)/sqrt(NSubjects), '-k');
for ii = 1:NContrastLevels
    plot(log10(theContrastsScaled(ii)*100), -CRF_LMS_mean(ii), 's', 'LineStyle', 'none', 'Color', 'k', 'MarkerFaceColor', RGBCols(ii, :)/255);
    plot(log10(theContrastsScaled(ii)*100), -CRF_Mel_mean(ii), 's', 'LineStyle', 'none', 'Color', 'k', 'MarkerFaceColor', RGBColsMel(ii, :)/255);
end

set(gca, 'XTick', log10(theContrastsScaled*100), 'XTickLabel', theContrastsScaled*100);
xlabel('Contrast [pct]');
ylabel('Minimum pupil constriction [prop]');
ylim([0 0.5]);
set(gca, 'TickDir', 'out'); box off;
pbaspect([1 1 1])
title({'CRF' '\pmSEM [subs, n=4]'});

set(crfFig, 'PaperPosition', [0 0 4 4]);
set(crfFig, 'PaperSize', [4 4]);
saveas(crfFig, '~/Desktop/CRF.png', 'png');
close(crfFig);