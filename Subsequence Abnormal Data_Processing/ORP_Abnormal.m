% ORP Background Fitting and Anomaly Detection (Using adaptive iterative algorithm)
% Data saved in orp_al

clc; 
clear all

%% 1. FILE SELECTION AND VALIDATION
filename = 'Qianlong-2 AUV historical detection dataset.xlsx';

% Check file existence
if ~exist(filename, 'file')
    error('File not found. Ensure the dataset file is in current directory.');
end

% Sheet selection
sheets = sheetnames(filename);
nSheets = length(sheets);
disp('Available worksheets:');
for i = 1:nSheets
    fprintf('%d: %s\n', i, char(sheets(i)));
end

sheetIdx = input(['Select worksheet index (1-', num2str(nSheets), '): ']);
sheetIdx = max(1, min(nSheets, round(sheetIdx)));
selectedSheet = sheets(sheetIdx);

%% 2. DATA EXTRACTION AND PREPROCESSING
data1 = xlsread(filename, selectedSheet);

% Extract time and ORP data
time = data1(:, 1);    % Time series
orp = data1(:, 7);     % ORP values

% Plot parameters
Font = 12;
linewidth = 2;
Time_step = 3;         % X-axis interval (hours)

% Noise removal and filtering
windowSize = 30;
data0 = orp;
[filteredData] = fun2_quzao(data0, windowSize, time);
orp = filteredData;

%% 3. AUTOMATIC BASELINE FITTING
x = time;   % Time data
y = orp;    % ORP data

% Algorithm parameters
iteration = 0;
degree = 3;                 % Polynomial degree
max_iterations = 30;        % Maximum iterations
tolerance = 0.01;           % Convergence tolerance (mV)

% Iterative baseline fitting (upper envelope for ORP)
while iteration < max_iterations
    % Fit polynomial curve
    p = polyfit(x, y, degree);
    y_fit = polyval(p, x);
    
    % Check convergence
    if abs(max(y) - max(y_fit)) < tolerance 
        break;
    end
    
    % Remove points below fitted curve (ORP baseline is upper envelope)
    indices_to_keep = y >= y_fit;
    x = x(indices_to_keep);
    y = y(indices_to_keep);
    
    iteration = iteration + 1;
end

disp(['Baseline correction completed. Iterations: ', num2str(iteration)]);
orp_Fit = polyval(p, time);

%% 4. VISUALIZATION - ORIGINAL VS BACKGROUND
figure(1)
plot(time, orp, 'o', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', linewidth);
xlim([min(time) max(time)]);
set(gca, 'XTick', [min(time)+Time_step/24-mod(min(time),Time_step/24):Time_step/24:max(time)-mod(max(time),Time_step/24)]);
datetick('x', 'HH:MM', 'keeplimits');
grid on;
title('Original and Background ORP Values', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
ylabel('mV', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
hold on;
plot(time, orp_Fit, 'o', 'MarkerEdgeColor', 'm', 'MarkerFaceColor', 'm', 'MarkerSize', linewidth);
legend('Original', 'Background', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
set(gca, 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
hold off;

%% 5. ANOMALY DETECTION AND MANUAL LABELING
% Calculate deviation from baseline (ORP: baseline - actual)
delta_orp = orp_Fit - orp;

% Automatic anomaly detection (threshold = 3 mV)
c = 3;
yichang_id = find(delta_orp > c);

% Initialize labels
orp_title = zeros(size(delta_orp));
orp_title(yichang_id) = 1;

% Plot anomalies
figure(2);
plot(time, delta_orp, 'o', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', linewidth);
hold on;
plot(time(yichang_id), delta_orp(yichang_id), 'o', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', linewidth);
grid on;
xlim([min(time) max(time)]);
set(gca, 'XTick', [min(time)+Time_step/24-mod(min(time),Time_step/24):Time_step/24:max(time)-mod(max(time),Time_step/24)]);
datetick('x', 'HH:MM', 'keeplimits');
title('Abnormal ORP Values', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
ylabel('mV', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');

% Manual anomaly labeling
disp('Regions with delta_orp > 5 mV are considered abnormal');
input_param3 = input('Manual ORP anomaly labeling? (1/0): ');
i = 1;

while input_param3 ~= 0
    % Select time range manually
    points = ginput(2);
    x1_3(i) = points(1, 1);
    x2_3(i) = points(2, 1);
    idx1_3(i) = find(time >= x1_3(i), 1, 'first');
    idx2_3(i) = find(time <= x2_3(i), 1, 'last');
    
    % Assign label
    b = input('ORP anomaly label (1 or 0): ');
    orp_title(idx1_3(i):idx2_3(i)) = b;
    
    % Visual feedback
    if b == 1
        plot(time(idx1_3(i):idx2_3(i)), delta_orp(idx1_3(i):idx2_3(i)), 'ro', 'MarkerSize', linewidth);
    else
        plot(time(idx1_3(i):idx2_3(i)), delta_orp(idx1_3(i):idx2_3(i)), 'go', 'MarkerSize', linewidth);
    end
    
    input_param3 = input('Continue? (1/0): ');
    if input_param3 == 0
        disp('ORP labeling completed');
    else
        disp(['Labeling cycles: ', num2str(i)]);
    end
    i = i + 1;
end

plot(time, orp_title * max(delta_orp), 'b-', 'MarkerSize', linewidth);
legend('', 'Abnormal Data', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
hold off;

%% 6. FINAL VISUALIZATION
yichang_id = find(orp_title == 1);

figure(3);
plot(time, orp, 'o', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', linewidth);
hold on;

plot(time, orp_Fit, 'o', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', linewidth);
plot(time(yichang_id), orp(yichang_id), 'o',  'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', linewidth);

xlim([min(time) max(time)]);
set(gca, 'XTick', [min(time)+Time_step/24-mod(min(time),Time_step/24):Time_step/24:max(time)-mod(max(time),Time_step/24)]);
datetick('x', 'HH:MM', 'keeplimits');
title('Abnormal and Background ORP Data', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
ylabel('mV', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
set(gca, 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
legend('Normal', 'Background', 'Abnormal', 'fontsize', Font, 'fontname', 'Times New Roman', 'fontweight', 'bold');
grid on;
hold off;

%% 7. DATA SAVING
% Compile results
orp_al = [];
orp_al(:, 1) = time;        % Time
orp_al(:, 2) = orp;         % ORP values
orp_al(:, 3) = delta_orp;   % Deviation from baseline
orp_al(:, 4) = orp_title;   % Anomaly labels

% Save data
b = input('Save data? (1/0): ');
if b == 1
    save('orp_al.mat', 'orp_al');
    disp('Data saved successfully');
else
    disp('Data not saved');
end