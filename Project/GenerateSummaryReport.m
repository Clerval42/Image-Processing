%% Summary Report Generator
% Consolidates all results and creates a summary table
clear all; close all; clc;

projectPath = fileparts(mfilename('fullpath'));
outputPath = fullfile(projectPath, 'Results');

if ~isdir(outputPath)
    mkdir(outputPath);
end

fprintf('========================================\n');
fprintf('  BIM472 PROJECT 2 - SUMMARY REPORT\n');
fprintf('========================================\n\n');

%% Load Localization Results
if isfile('results.csv')
    fprintf('Loading localization results...\n');
    locResults = readtable('results.csv');
    
    % OD Localization
    od_dists = locResults.OD_Dist(~isnan(locResults.OD_Dist));
    fprintf('\nOPTIC DISC CENTER LOCALIZATION:\n');
    fprintf('  Mean Error:    %.2f pixels\n', mean(od_dists));
    fprintf('  Std Dev:       %.2f pixels\n', std(od_dists));
    fprintf('  Median Error:  %.2f pixels\n', median(od_dists));
    fprintf('  Max Error:     %.2f pixels\n', max(od_dists));
    fprintf('  Images:        %d\n', length(od_dists));
    
    % Fovea Localization
    fovea_dists = locResults.Fovea_Dist(~isnan(locResults.Fovea_Dist));
    fprintf('\nFOVEA CENTER LOCALIZATION:\n');
    fprintf('  Mean Error:    %.2f pixels\n', mean(fovea_dists));
    fprintf('  Std Dev:       %.2f pixels\n', std(fovea_dists));
    fprintf('  Median Error:  %.2f pixels\n', median(fovea_dists));
    fprintf('  Max Error:     %.2f pixels\n', max(fovea_dists));
    fprintf('  Images:        %d\n', length(fovea_dists));
else
    fprintf('WARNING: results.csv not found. Run Preprocessing.m first.\n');
end

%% Load OD Segmentation Results
if isfile('od_segmentation_results.csv')
    fprintf('\n\nOPTIC DISC SEGMENTATION:\n');
    segResults = readtable('od_segmentation_results.csv');
    
    fprintf('  Mean Precision: %.4f\n', mean(segResults.Precision));
    fprintf('  Mean Recall:    %.4f\n', mean(segResults.Recall));
    fprintf('  Mean F-Score:   %.4f\n', mean(segResults.F_Score));
    fprintf('  Mean Dice:      %.4f\n', mean(segResults.Dice));
    fprintf('  Mean IoU:       %.4f\n', mean(segResults.IoU));
    
    % Calculate combined metric (for report)
    avgFScore = mean(segResults.F_Score);
    avgDice = mean(segResults.Dice);
    
else
    fprintf('WARNING: od_segmentation_results.csv not found. Run EvaluateODSegmentation.m first.\n');
    avgFScore = NaN;
    avgDice = NaN;
end

%% Overall Performance Summary
fprintf('\n========================================\n');
fprintf('  FINAL METRICS FOR REPORT\n');
fprintf('========================================\n');
fprintf('\nLocalization Performance:\n');
fprintf('  OD Error:    %.2f ± %.2f px\n', mean(od_dists), std(od_dists));
fprintf('  Fovea Error: %.2f ± %.2f px\n', mean(fovea_dists), std(fovea_dists));

fprintf('\nSegmentation Performance:\n');
fprintf('  F-Score:     %.4f\n', avgFScore);
fprintf('  Dice Index:  %.4f\n', avgDice);

fprintf('\n========================================\n');
fprintf('\nNext steps:\n');
fprintf('1. Review Figures/ directory for visualization\n');
fprintf('2. Update BIM472_Template.doc with results\n');
fprintf('3. Include figures and tables in report\n');
fprintf('4. Create PowerPoint presentation\n');
