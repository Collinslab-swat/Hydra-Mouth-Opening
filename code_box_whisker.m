function code_box_whisker(foldername, filename, scale)

% Generates a box-whisker plot of 3 groups that also shows the individual data points using scatter
% save the associated data in a MATLAB file in the same folder specified by
% 'foldername' and 'filename' need to be specified in the Matlab workspace
% e.g. filename='Data.csv'


%INPUT
%foldername - where data is stored and .mat file and plots will be saved
%filename - name of file with .csv extension
%scale - um per pixel conversion (e.g. 0.87)

%OUTPUT
% box plot and .mat file saved in the folder specified by 'foldername'

% Extract the folder name to your data (without full path)
[~, folderName] = fileparts(foldername);
% Create output filename
outputFileName = fullfile(foldername, sprintf('Data_%s.mat', folderName)); 

%cd(foldername);
%scale conversion
scale = (scale^2);

% read in file with the data
all_data = readmatrix(filename);
control = all_data(:, 1);  % First column
group1 = all_data(:, 2);  % Second column
group2 = all_data(:, 3);  % Third column


% Create a grouping variable (1,2,3 for each group)
group = [ones(length(control),1); 
         2*ones(length(group1), 1);
         3*ones(length(group2), 1);
         ]; 
     

% Create boxplot
figure(1);

boxplot(all_data, group,'Labels',{'control','31.6 μM DP','56.2 μM DP'},'Colors','kkk');

% Overlay the data points with a swarmchart
% Arguments: X-coordinates (groups), Y-coordinates (data), marker size

colors = [00.5843 0.8157 0.9882;   % light blue for group 1 (DMSO)
          1.0 0.5 0.0 ;    % orange for group 2 (DP31.6)
          0.5 0 0.5];  % purple for group 3 (DP56.2)

groups = unique(group); % your category variable
hold on;
for i = 1:3
    idx = group == groups(i);
    swarmchart(repmat(i, sum(idx), 1), all_data(idx), 100, colors(i,:),'filled', 'LineWidth',5,'XJitter', 'rand', 'XJitterWidth', 0.1);
end
grid off;

ylabel('critical area (μm^2) ')


set(gca,'FontSize',35)
saveas(gcf, 'boxplot_critical area.svg');