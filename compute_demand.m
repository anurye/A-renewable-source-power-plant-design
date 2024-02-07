%% This script computes the demand, in our case which is very simple
% The power sent to the grid should not exceed 60kW at any time.

% read time data from metoData
metoData = readtable("d.csv");
Demand = metoData(:, "time");
Demand.Max_Power(:) = 60000;

% save demand
writetable(Demand, 'max_demand.csv');
