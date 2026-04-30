%% Main entry point to run full pipeline
function Main()
    projectPath = fileparts(mfilename('fullpath'));
    cd(projectPath);

    fprintf('Running full pipeline in: %s\n', projectPath);

    % 1) Localization + OD detection (results.csv)
    Preprocessing;

    % 2) OD segmentation evaluation (od_segmentation_results.csv)
    EvaluateODSegmentation;

    % 3) Report figures (Figures/)
    GenerateReportFigures;

    % 4) Summary report (Results/)
    GenerateSummaryReport;

    fprintf('\nAll steps finished.\n');
end
