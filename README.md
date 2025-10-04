# Offline-Processing-Methods-for-Hydrothermal-Detection-Dataset
To label hydrothermal anomaly data from the hydrothermal detection dataset obtained by the "Qianlong-2" AUV, point anomaly data (temperature and turbidity) are labeled via a K-medoids clustering algorithm, while subsequence anomaly data (methane and oxidation-reduction potential) are labeled using an adaptive iterative algorithm.
# Data description
During the period from 2016 to 2020, the "Qianlong-2" AUV obtaining rich and high-quality hydrothermal detection dataset in the Southwest Indian Mid-Ocean Ridge, including Depth (m), Salinity (‰), Temperature (°C), Turbidity (FTU), Methane (nmol/L), ORP (mV). Moreover, the sampling frequency of all data is 1 Hz.
# Processing Method
Typically, abnormal data in time series data can be initially classified into two categories, point abnormal data and subsequence abnormal data.

On the one hand, abnormal data of temperature and turbidity are classified as point abnormal data, that is, abnormal data can be identified by judging whether the characteristic values of the data points are far from the normal range. Mark the abnormal data of temperature and turbidity from the historical detection dataset in the same dive through the K-medoids clustering algorithm.

On the other hand, abnormal data of methane concentration and ORP are regarded as subsequence abnormal data, that is, abnormal data can be identified by judging whether a continuous period of data in the time series shows abnormal behavior. Mark the abnormal data of methane concentration and ORP from the historical detection dataset in the same dive through an adaptive iterative algorithm.

