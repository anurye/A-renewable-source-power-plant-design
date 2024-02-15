% -------------------------------------------------------------------------
% RESPowerPlantAnalysis.m: Renewable Energy Source Power Plant Desing
% Analysis
%
% Description:
%   This script presents the design of a renewable energy sources power
%   plant design combining PV panels, wind turbines, and a 
%   battery storage system. It reads meteorological and max-demand data, 
%   determines the number of PV modules and turbines necessary to generate
%   a required power, analyzes the system's power generation and storage
%   capabilities, and finally presents the summary of the system performance.
%
% Required Instances:
%   - PV: PV module class
%   - windTurbine: Wind turbine class
%   - batterySystem: Battery system class
%
% Required input datas:
%   - meteorological data file: 'metoData.csv'
%   - maximum demand data file: 'max_demand.csv'
%
% Usage:
%   1. Ensure the required data files are present in the same directory.
%   2. Execute the script.
%
% -------------------------------------------------------------------------

%% Add the Content of './src' directory to MATLAB PATH
clear; close all; clc;
initialize;

%% Creating Instances and Initialization
% Instance of PV and windTurbine
efficiencyRef = 0.227;
temperatureRef = 25;
betta = -0.27;
surfaceArea = 1.812*1.046;
PVmodule = PV(efficiencyRef, temperatureRef, betta, surfaceArea);

startingWindVelocity = 2;
nominalWindVelocity = 11;
maximumWindVelocity = 30;
maximumPower = 60e3;
Turbine = windTurbine(startingWindVelocity, nominalWindVelocity, ...
    maximumWindVelocity, maximumPower);

% Number of PV modules and Wind Turbines - Final Iteration
N_PV = 250;
N_Turbine = 7;

% Storage System (one module) - for initial iteration
%{
maxPower = 70*57.6*32;
capacity = 5*1e3*32;
efficiency = 0.95;
selfDischarge = 1;
% Storage system - overall (3 modules)
maxPower = 4*3*maxPower;
capacity = 4*3*capacity;
%}

% Finally chosen battery -  MC Cube ESS
maxPower = 1236e3;
capacity = 5365e3;
efficiency = 0.9;
selfDischarge = 1;

battery = batterySystem(maxPower, capacity, efficiency, selfDischarge);

%% Reading Data
% Read meteorological data
metoData = readtable("metoData.csv");

% Read maximum demand data
Demand = readtable("max_demand.csv");

%% Determination of number of PV and Turbines
% First based on the meteorological data let's determine the average power
% based on the average wind speed and the average irradiance
average_ws = sum(metoData.WS10m)/height(metoData); % average wind speed
average_I = sum(metoData.G_i_)/height(metoData);   % average radiation
average_Temp = sum(metoData.T2m)/height(metoData); % average temperature

disp("Average value of environmental variables:")
fprintf("--> Average temperature of the year: %.4fC\n", average_Temp);
fprintf("--> Average radiation of the year: %.4fW/m^2\n", average_I);
fprintf("--> Average wind speed of the year: %.4fm/s\n\n", average_ws);

% Now lets determine the average power one turbine and one PV can produce
% throughout the year
Turbine_Power_avg = Turbine.calculatePower(average_ws);
PV_Power_avg = PVmodule.powerOutPutFree(average_I, average_Temp, average_ws);

disp("Because of the enviromenatl factors:")
fprintf("-->Based on the metoData a turbine rated at %.2fkW generates about" + ...
    " %.2fkW in average\n", maximumPower/1e3, Turbine_Power_avg/1e3);
fprintf("-->Based on the metoData the PV panel generates about " + ...
    "%.4fW in average\n\n", PV_Power_avg);

% Now, let's determine how many wind turbines will be required to generate
% the maximum allowable power that can be sent to the grid, 60kW.
N_Turbine_max = round(60000/Turbine_Power_avg);
N_PV_max = round(60000/PV_Power_avg);

disp("If the system were to be designed with only one kind of energy source:")
fprintf("-->Based on the metoData, to get 60kW the number of Turbines that is" + ...
    " required is: %d\n", N_Turbine_max);
fprintf("-->Based on the metoData, to get 60kW the number of PV modules that" + ...
    " is required is: %d\n", N_PV_max);


%% Analysis
% Initialize system table
system = metoData(:, "time");

% Generated Power
system.PV_power = N_PV * PVmodule.powerOutPutFree(metoData.G_i_, ...
    metoData.T2m, metoData.WS10m);
system.Turbine_Power = N_Turbine * Turbine.calculatePower(metoData.WS10m);
system.RES_power = system.PV_power + system.Turbine_Power;

% Determine if there is more power generated than the maximum allowable
% power that can be send to the grid (60kW), if so store it in the battery
system.excessForBattery = Demand.Max_Power - system.RES_power;

% Determine what can be sent to the grid if there were no battery
% if less than 60kW is generated then send waht is generated else send the
% maximum possible, which is 60kW.
idx_no_battery = system.RES_power <= 6e4;
system.ToGridNoBattery(idx_no_battery) = system.RES_power(idx_no_battery);
system.ToGridNoBattery(~idx_no_battery) = 6e4;
%{
plot(system.time, system.RES_power)
xlabel("Hour of the year (h)")
ylabel("Power (W)")
%}

% Battery
if system.excessForBattery(1) < 0
    [system.batteryEnergy(1), system.batteryPower(1)]= ...
        battery1.calculateEnergy(-system.excessForBattery(1), 0);
else
    system.batteryEnergy(1) = 0;
end

for year = 1:3  % repeat to get stable solution
    for hourIterator = 2:height(system)
        [system.batteryEnergy(hourIterator), system.batteryPower(hourIterator)]= ...
            battery.calculateEnergy(-system.excessForBattery(hourIterator), ...
            system.batteryEnergy(hourIterator-1));
    end
end

% Calculate what can be sent to the grid
idx_battery_power = system.batteryPower < 0;
system.balance = system.ToGridNoBattery;
system.balance(idx_battery_power) = system.ToGridNoBattery(idx_battery_power) -...
    system.batteryPower(idx_battery_power);

% Calculate what can be send to the grid with battery
idx_to_grid_battery = system.balance < 6e4;
system.ToGridBattery(idx_to_grid_battery) = system.balance(idx_to_grid_battery);
system.ToGridBattery(~idx_to_grid_battery) = 6e4;

% Calculate excess power generated
% With Battery
idx_excess = system.excessForBattery < 0;
system.excessPowerWithBattery(idx_excess) = abs(system.excessForBattery(idx_excess)) -...
    system.batteryPower(idx_excess);
% Without Battery - which is the same as the excess power that was
% generated to charge the battery plus the excess power with battery
idx_excess = system.excessForBattery < 0;
system.excessPowerWithoutBattery(idx_excess) = system.excessForBattery(idx_excess);

% Battery power at the end of the year
system.batteryPowerAtEnd = system.batteryPower;


Summary = table();
Summary.MaxAllowableToGrid = sum(Demand.Max_Power)/1e6; %MWh
Summary.PV = sum(system.PV_power)/1e6;
Summary.Turbine = sum(system.Turbine_Power)/1e6;
Summary.ToGridWithBattery = abs(sum(system.ToGridBattery)/1e6);
Summary.ToGridWithoutBattery = abs(sum(system.ToGridNoBattery)/1e6);
Summary.excessPowerWithBattery = sum(system.excessPowerWithBattery)/1e6;
Summary.excessPowerWithoutBattery = abs(sum(system.excessPowerWithoutBattery))/1e6;
Summary.batteryPowerAtEnd = sum(system.batteryPowerAtEnd)/1e6;

% Visualization
% Plot of the total generated power
figure
plot(system.RES_power/1e6, 'b', "DisplayName", "RES power")
hold on
plot(system.ToGridBattery/1e6, 'g', "LineWidth", 1.3, "DisplayName", "To Grid")
plot(system.excessPowerWithBattery/1e6, 'r', "DisplayName", "Excess")
plot(abs(system.batteryPower)/1e6, 'k', "DisplayName","Battery")
hold off
title("Power Vs. time")
ylabel("Power [mW]", "FontSize",13, "FontWeight","bold")
xlabel("Time [s]", "FontSize",13, "FontWeight","bold")
legend("Location", "best", "FontSize",13, "FontWeight","bold")
axis padded
grid on

% Visualization of overall summary
figure;
bar(Summary{1,:})
% labels and title
title("Summary of the power plant performance")
ylabel("Energy (MWh)");
xticklabels(Summary.Properties.VariableNames)
grid on

%% Income generated yearly
Energy_Price = 290; %Euro/MWh

InclomeWithBattery = Energy_Price*Summary.ToGridWithBattery;
InclomeWithoutBattery = Energy_Price*Summary.ToGridWithoutBattery;

fprintf('\nYearly Income; System with battery: €%.2f\n', InclomeWithBattery);
fprintf('Yearly Income; System without battery: €%.2f\n', InclomeWithoutBattery);

