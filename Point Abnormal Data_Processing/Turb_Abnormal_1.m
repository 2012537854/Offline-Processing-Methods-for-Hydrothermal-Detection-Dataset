% Turbidity Outlier Detection using Sliding Window and Polynomial Fitting
% Purpose: Generate turbidity anomaly features for clustering analysis

clear; clc;

%% 1. PARAMETER CONFIGURATION
filename = 'Qianlong-2 AUV historical detection dataset.xlsx';
Font = 12;
FontSize = 12;
linewidth = 2;
Time_step = 3; % Time axis interval (hours)
window_size = 10; % Moving average window size
feature_window = 15; % Window size for feature extraction
poly_degree = 2; % Polynomial fitting degree

%% 2. FILE READING AND SHEET SELECTION
if ~exist(filename, 'file')
    error('File not found. Ensure the dataset file is in current directory.');
end

sheets = sheetnames(filename);
nSheets = length(sheets);
disp('Available worksheets:');
for i = 1:nSheets
    fprintf('%d: %s\n', i, char(sheets(i)));
end

sheetIdx = input(['Select worksheet index (1-', num2str(nSheets), '): ']);
sheetIdx = max(1, min(nSheets, round(sheetIdx)));
selectedSheet = sheets(sheetIdx);

%% 3. DATA EXTRACTION AND MOVING AVERAGE CALCULATION
data = xlsread(filename, selectedSheet);
time = data(:, 1); % Time
dep = data(:, 2);  % Depth
tem = data(:, 4);  % Temperature
turb = data(:, 5); % Turbidity (新增浊度数据)

% Calculate moving averages for turbidity and depth (修改为浊度和深度)
n = length(turb);
turb_ma = zeros(n, 1);
dep_ma = zeros(n, 1); % 使用深度作为参考变量

for i = window_size:n
    turb_ma(i) = mean(turb(i-window_size+1:i));
    dep_ma(i) = mean(dep(i-window_size+1:i));
end

% Fill initial values
turb_ma(1:window_size-1) = turb_ma(window_size);
dep_ma(1:window_size-1) = dep_ma(window_size);

%% 4. PLOT RAW DATA
figure(1);
parameters = [2, 4, 5]; % 增加第5列浊度
units = {'m', '℃', 'NTU'}; % 浊度单位NTU
titles = {'Depth','Temperature', 'Turbidity'}; % 增加浊度标题

for i = 1:3
    subplot(3, 1, i);
    plot(time, data(:, parameters(i)), 'r+', 'MarkerSize', linewidth);
    xlim([min(time), max(time)]);
    set(gca, 'XTick', min(time):Time_step/24:max(time));
    datetick('x', 'HH:MM', 'keeplimits');
    title(titles{i}, 'FontSize', Font, 'FontWeight', 'bold');
    ylabel(units{i}, 'FontSize', Font, 'FontWeight', 'bold');
    set(gca, 'FontSize', FontSize, 'FontWeight', 'bold');
    grid on;
end

%% 5. INTERACTIVE BACKGROUND REGION SELECTION
bg_turb = [];
bg_dep = []; % 修改为深度数据
segment_end = 1;

disp('Select background regions (click two points for each region, Esc to finish)');
continue_select = 1;
selection_count = 0;

while continue_select == 1
    selection_count = selection_count + 1;
    fprintf('Select region %d: click two points\n', selection_count);
    
    try
        points = ginput(2);
        
        % Find indices for selected time range
        idx1 = find(time >= points(1, 1), 1, 'first');
        idx2 = find(time >= points(2, 1), 1, 'first');
        
        fprintf('Selected range: %s to %s\n', datestr(time(idx1)), datestr(time(idx2)));
        
        % Extract background data
        current_length = idx2 - idx1 + 1;
        bg_turb(segment_end:segment_end+current_length-1) = turb_ma(idx1:idx2);
        bg_dep(segment_end:segment_end+current_length-1) = dep_ma(idx1:idx2);
        
        segment_end = segment_end + current_length;
        continue_select = input('Continue selection? (1=Yes, 0=No): ');
    catch
        disp('Selection cancelled or invalid input');
        continue_select = 0;
    end
end

bg_turb = bg_turb(:);
bg_dep = bg_dep(:);

%% 6. POLYNOMIAL FITTING AND ANOMALY DETECTION
% Fit polynomial: Turbidity = f(Depth) (修改为浊度与深度的关系)
p = polyfit(bg_dep, bg_turb, poly_degree);
pearson_corr = corr(bg_turb, bg_dep, 'Type', 'Pearson');
fprintf('Pearson correlation coefficient: %.4f\n', pearson_corr);

% Calculate background turbidity and anomalies
turb_background = polyval(p, dep_ma);
turb_anomaly = turb_ma - turb_background;

%% 7. FEATURE EXTRACTION FROM ANOMALIES
% Extract statistical features using sliding window
n = length(turb_anomaly);
features = zeros(n, 7); % [mean, std, median, Q1, Q3, skewness, kurtosis]

for i = feature_window:n
    window = turb_anomaly(i-feature_window+1:i);
    features(i, 1) = mean(window);
    features(i, 2) = std(window);
    features(i, 3) = median(window);
    features(i, 4) = quantile(window, 0.25);
    features(i, 5) = quantile(window, 0.75);
    features(i, 6) = skewness(window);
    features(i, 7) = kurtosis(window);
end

% Fill initial values
for i = 1:feature_window-1
    features(i, :) = features(feature_window, :);
end

% Create final feature matrix
feature_matrix = [time, turb, turb_anomaly, features];

%% 8. VISUALIZATION
% Plot comparison: Original vs Background turbidity
figure(2);
plot(turb_ma, dep_ma, 'ob', 'MarkerSize', linewidth+1, 'MarkerFaceColor', 'b');
hold on;
plot(turb_background, dep_ma, 'om', 'MarkerSize', linewidth+1, 'MarkerFaceColor', 'm');
title('Original vs Background Turbidity', 'FontSize', Font, 'FontWeight', 'bold');
xlabel('Turbidity (NTU)', 'FontSize', Font, 'FontWeight', 'bold');
ylabel('Depth (m)', 'FontSize', Font, 'FontWeight', 'bold');
legend('Original', 'Background', 'FontSize', Font);
set(gca, 'FontSize', FontSize, 'FontWeight', 'bold');
grid on;
hold off;

% Plot turbidity anomalies over time
figure(3);
plot(time, turb_anomaly, 'og', 'MarkerSize', linewidth, 'MarkerFaceColor', 'g');
xlim([min(time), max(time)]);
set(gca, 'XTick', min(time):Time_step/24:max(time));
datetick('x', 'HH:MM', 'keeplimits');
title('Turbidity Anomalies', 'FontSize', Font, 'FontWeight', 'bold');
ylabel('Anomaly Magnitude (NTU)', 'FontSize', Font, 'FontWeight', 'bold');
set(gca, 'FontSize', FontSize, 'FontWeight', 'bold');
grid on;

%% 9. DATA SAVING
save_choice = input('Save data? (1=Yes, 0=No): ');
if save_choice == 1
    save('turb_pre.mat', 'feature_matrix');
    disp('Data saved successfully as turb_pre.mat');
else
    disp('Data not saved.');
end

disp('Processing completed.');