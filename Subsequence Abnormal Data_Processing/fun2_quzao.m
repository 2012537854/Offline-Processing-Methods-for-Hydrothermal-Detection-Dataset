% 预处理——去噪
% 处理一维数据
% 应用于甲烷、ORP数据
% 数据在filteredData

function [filteredData] = fun2_quzao(data0,windowSize,time)

Font=12;
linewidth=2;
Time_step=3;%横坐标坐标间隔两小时

% 参数设置
data = data0; % 示例数据，实际数据替换这行
numPoints = length(data);

% 初始化结果数据
filteredData = data;

% 遍历数据中的每个点
for i = 1:numPoints
    % 确定滑动窗口的起始和结束位置
    startIdx = max(1, i - floor(windowSize/2));
    endIdx = min(numPoints, i + floor(windowSize/2));
    
    % 提取滑动窗口中的数据
    windowData = data(startIdx:endIdx);
    
    % 计算窗口中的平均值和标准差
    windowMean = mean(windowData);
    windowStd = std(windowData);
    
    % 判断当前点是否为噪声点（大于平均值1倍标准差）
    if abs(data(i) - windowMean) > 1 * windowStd
        % 将噪声点替换为窗口的中位数
        filteredData(i) = median(windowData) ; %max(windowData)
    end
end

filteredData = movmean(filteredData, windowSize); %滑动平均滤波

% 绘制原始数据和去噪后的数据进行比较

figure(11)
subplot(2,1,1);
plot(time,data,'o', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b','MarkerSize', linewidth);
xlim([min(time) max(time)]);
set(gca,'XTick',[min(time)+Time_step/24-mod(min(time),Time_step/24):Time_step/24:max(time)-mod(max(time),Time_step/24)]);
datetick('x','HH:MM','keeplimits');
title('Original Data','fontsize',Font,'fontname','Times New Roman','fontweight','bold');%设置标题
ylabel( 'mv' ,'fontsize',Font,'fontname','Times New Roman','fontweight','bold');
grid on;
hold on;

subplot(2,1,2);
plot(time,filteredData,'o', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r','MarkerSize', linewidth);
xlim([min(time) max(time)]);
set(gca,'XTick',[min(time)+Time_step/24-mod(min(time),Time_step/24):Time_step/24:max(time)-mod(max(time),Time_step/24)]);
datetick('x','HH:MM','keeplimits');
title('Denoised Data','fontsize',Font,'fontname','Times New Roman','fontweight','bold');%设置标题
ylabel( 'mv' ,'fontsize',Font,'fontname','Times New Roman','fontweight','bold');
grid on;
hold off;

