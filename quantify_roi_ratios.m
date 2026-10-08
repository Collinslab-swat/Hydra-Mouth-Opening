function R = quantify_roi_ratios()
% QUANTIFY_ROI_RATIOS  Interactively measure a pixel-intensity ratio
% between two regions of interest (ROIs) across a series of TIFF images.
%
% WORKFLOW:
%   1. User selects a .tif/.tiff file to load.
%   2. User draws a rectangular ROI ("Region 1") on the image.
%      -> Mean pixel intensity within this ROI is stored as A1.
%   3. A duplicate ROI of the SAME SIZE appears on the image. The user
%      drags it (resizing is disabled) to a second location ("Region 2").
%      -> Mean pixel intensity within this ROI is stored as A2.
%   4. The ratio A2/A1 is computed and appended, together with the
%      source filename, as a new row of the output table R.
%   5. User is asked whether to analyze another image; the loop ends
%      when the user selects "No" (or cancels the file dialog).
%   6. Once finished, the user is asked to choose a folder, and R is
%      saved there as both a .mat file and a .csv file.
%
% USAGE
%   R = quantify_roi_ratios();
%
% OUTPUT
%   R - an N-row table, one row per image, with variables:
%       FileName (string), A1, A2, Ratio (A2/A1)
%
% NOTES
% Double-click inside an ROI to confirm its placement/size and
%     continue.
% The body colum region is selected first (A1), the head region second (A2)
% --> if pixel intensity is smaller in A2 than in A1, the resulting ratio
% will be a number between 0 and 1
% For Region 2, only dragging (translation) is allowed - the ROI
%     size is locked to match Region 1 exactly.
% RGB images are converted to grayscale (via rgb2gray) before
%     intensity quantification. 
% Multi-frame/stack TIFFs are not supported

    % Preallocate results as growable arrays, assembled into a table
    % at the end 
    fileNames = strings(0, 1);
    A1_all    = [];
    A2_all    = [];
    Ratio_all = [];

    imageCount = 0;
    keepGoing = true;

    while keepGoing
        imageCount = imageCount + 1;

        % ---------- 1. Load image ----------
        [fileName, filePath] = uigetfile( ...
            {'*.tif;*.tiff', 'TIFF Images (*.tif, *.tiff)'}, ...
            sprintf('Select image #%d', imageCount));

        if isequal(fileName, 0)
            disp('No file selected - stopping.');
            imageCount = imageCount - 1; % this attempt didn't count
            break;
        end

        fullFileName = fullfile(filePath, fileName);
        img = imread(fullFileName);

        % Convert to grayscale double precision 
        if size(img, 3) == 3
            imgGray = double(rgb2gray(img));
        else
            imgGray = double(img(:, :, 1));
        end

        % ---------- 2. Display image and draw Region 1 ----------
        fig = figure('Name', sprintf('Image %d: %s', imageCount, fileName), ...
            'NumberTitle', 'off');
        imshow(imgGray, []);
        colormap(gca, gray);
        title({sprintf('Image %d: %s', imageCount, fileName), ...
               'Draw Region 1 (red), then double-click inside it to confirm'}, ...
               'Interpreter', 'none');
        roi1 = drawrectangle(gca, 'Color', 'r');
        wait(roi1);   % blocks until user double-clicks to confirm

        mask1 = createMask(roi1);
        A1 = mean(imgGray(mask1));

        % ---------- 3. Duplicate ROI (same size) - user translates it ----------
        pos1 = roi1.Position;   % [x y width height]
        title({sprintf('Image %d: %s', imageCount, fileName), ...
               'Drag Region 2 (same size; cyan) to a new location, then double-click to confirm'}, ...
               'Interpreter', 'none');

        roi2 = drawrectangle(gca, 'Position', pos1, 'Color', 'c');
        roi2.InteractionsAllowed = 'translate';   % lock size; allow only moving
        wait(roi2);

        mask2 = createMask(roi2);
        A2 = mean(imgGray(mask2));

        close(fig);

        % ---------- 4. Compute ratio and store ----------
        Ratio = A2 / A1;

        fileNames(imageCount, 1) = string(fileName); %#ok<AGROW>
        A1_all(imageCount, 1)    = A1;                %#ok<AGROW>
        A2_all(imageCount, 1)    = A2;                %#ok<AGROW>
        Ratio_all(imageCount, 1) = Ratio;             %#ok<AGROW>

        fprintf('Image %d (%s):  A1 = %.3f   A2 = %.3f   R = %.4f\n', ...
            imageCount, fileName, A1, A2, Ratio);

        % ---------- 5. Continue or stop ----------
        choice = questdlg('Analyze another image?', 'Continue?', ...
            'Yes', 'No', 'Yes');
        if isempty(choice) || strcmp(choice, 'No')
            keepGoing = false;
        end
    end

    % ---------- 6. Assemble results table ----------
    R = table(fileNames, A1_all, A2_all, Ratio_all, ...
        'VariableNames', {'FileName', 'A1', 'A2', 'Ratio'});

    disp('Finished. Results table R:');
    disp(R);

    % ---------- 7. Ask user where to save R, and save it ----------
    if imageCount > 0
        saveDir = uigetdir(pwd, 'Select a folder to save the results table R');

        if isequal(saveDir, 0)
            disp('No folder selected - results were NOT saved to disk (R is still returned in the workspace).');
        else
            timestamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>

            matFile = fullfile(saveDir, ['roi_ratio_results_' timestamp '.mat']);
            csvFile = fullfile(saveDir, ['roi_ratio_results_' timestamp '.csv']);

            save(matFile, 'R');
            writetable(R, csvFile);

            fprintf('Results saved to:\n  %s\n  %s\n', matFile, csvFile);
        end
    else
        disp('No images were analyzed - nothing to save.');
    end
end
