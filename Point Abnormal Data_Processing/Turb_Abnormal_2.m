% K-medoids Clustering for Turbidity Anomaly Detection
% Purpose: Perform 5D clustering on turbidity features and label anomalies

clear; clc;

%% 1. PARAMETER CONFIGURATION
filename = 'turb_pre.mat'; % Input feature data
Font = 12;
linewidth = 2;
Time_step = 3; % Time axis interval (hours)

%% 2. DATA LOADING AND FEATURE EXTRACTION
if ~exist(filename, 'file')
    error('File not found. Ensure turb_pre.mat is in current directory.');
end

load(filename); % Load feature_matrix from previous processing

% Extract features from the dataset
time = feature_matrix(:, 1);      % Time
turbidity = feature_matrix(:, 2); % Original turbidity
turb_anomaly = feature_matrix(:, 3); % Turbidity anomaly
turb_mean = feature_matrix(:, 4);   % Moving average
turb_std = feature_matrix(:, 5);    % Standard deviation
turb_median = feature_matrix(:, 6); % Median
turb_Q1 = feature_matrix(:, 7);     % First quartile
turb_Q3 = feature_matrix(:, 8);     % Third quartile

% Prepare feature matrix for clustering (5-dimensional)
feature_matrix_5d = [turb_anomaly, turb_mean, turb_std, turb_median, turb_Q1, turb_Q3];

%% 3. K-MEDOIDS CLUSTERING
% Get number of clusters from user
k = input('Enter number of clusters: ');
if isempty(k) || k < 2 || k > 10
    k = 3; % Default value
    fprintf('Using default cluster number: %d\n', k);
end

% Perform K-medoids clustering
rng(1); % Set random seed for reproducibility
[idx, medoids, sumd] = kmedoids(feature_matrix_5d, k);

% Calculate cluster center statistics to identify anomaly cluster
cluster_sums = zeros(k, 1);
for i = 1:k
    cluster_sums(i) = sum(medoids(i, :));
end

% Identify anomaly cluster (cluster with maximum sum - likely outliers)
[~, anomaly_cluster] = max(cluster_sums);
anomaly_indices = (idx == anomaly_cluster);

fprintf('Cluster analysis completed:\n');
fprintf('Total data points: %d\n', length(idx));
fprintf('Anomaly cluster: %d (contains %d points)\n', anomaly_cluster, sum(anomaly_indices));

%% 4. 3D VISUALIZATION OF CLUSTERING RESULTS
figure(1);
colors = lines(k); % Generate distinct colors for each cluster

for i = 1:k
    cluster_points = (idx == i);
    scatter3(feature_matrix_5d(cluster_points, 1), ...
             feature_matrix_5d(cluster_points, 2), ...
             feature_matrix_5d(cluster_points, 3), ...
             30, colors(i, :), 'filled', 'DisplayName', sprintf('Cluster %d', i));
    hold on;
end

% Plot medoids
scatter3(medoids(:, 1), medoids(:, 2), medoids(:, 3), 100, 'k', 'filled', ...
         'DisplayName', 'Medoids', 'Marker', 'd');

xlabel('Turbidity Anomaly', 'FontSize', Font, 'FontWeight', 'bold');
ylabel('Moving Average', 'FontSize', Font, 'FontWeight', 'bold');
zlabel('Standard Deviation', 'FontSize', Font, 'FontWeight', 'bold');
title('K-medoids Clustering Results for Turbidity (3D View)', 'FontSize', Font, 'FontWeight', 'bold');
legend('show', 'FontSize', Font-2);
grid on;
hold off;

%% 5. 2D VISUALIZATION: NORMAL VS ABNORMAL DATA
figure(2);
% Plot normal points
normal_indices = ~anomaly_indices;
scatter(turb_mean(normal_indices), turb_std(normal_indices), 25, 'g', 'filled', ...
        'DisplayName', 'Normal');

hold on;
% Plot anomaly points
scatter(turb_mean(anomaly_indices), turb_std(anomaly_indices), 25, 'r', 'filled', ...
        'DisplayName', 'Anomaly');

title('Turbidity Data Clustering Results', 'FontSize', Font, 'FontWeight', 'bold');
xlabel('Moving Average (NTU)', 'FontSize', Font, 'FontWeight', 'bold');
ylabel('Standard Deviation', 'FontSize', Font, 'FontWeight', 'bold');
legend('show', 'FontSize', Font);
grid on;
hold off;

%% 6. TIME SERIES VISUALIZATION WITH ANOMALY LABELS
figure(3);
% Plot all turbidity data
scatter(time, turbidity, 12, 'g', 'filled','DisplayName', 'Normal');
hold on;
% Highlight anomaly points
scatter(time(anomaly_indices), turbidity(anomaly_indices), 12, 'r', 'filled', ...
        'DisplayName', 'Anomaly');

xlim([min(time), max(time)]);
set(gca, 'XTick', min(time):Time_step/24:max(time));
datetick('x', 'HH:MM', 'keeplimits');
title('Turbidity Data with Anomaly Detection', 'FontSize', Font, 'FontWeight', 'bold');
ylabel('Turbidity (NTU)', 'FontSize', Font, 'FontWeight', 'bold');
legend('show', 'FontSize', Font);
grid on;
hold off;

%% 7. PREPARE FINAL DATASET WITH CLUSTER LABELS
% Create final dataset with cluster labels in column 9
turb_al = [feature_matrix, idx]; % Add cluster labels as 9th column

% Display cluster statistics
fprintf('\nCluster Statistics:\n');
for i = 1:k
    cluster_size = sum(idx == i);
    percentage = (cluster_size / length(idx)) * 100;
    fprintf('Cluster %d: %d points (%.1f%%)\n', i, cluster_size, percentage);
end

%% 8. DATA SAVING
save_choice = input('Save results? (1=Yes, 0=No): ');
if save_choice == 1
    save('turb_al.mat', 'turb_al');
    fprintf('Data saved successfully as turb_al.mat\n');
    fprintf('Cluster labels stored in column 9 of turb_al matrix\n');
else
    fprintf('Data not saved.\n');
end

fprintf('Turbidity clustering analysis completed successfully.\n');