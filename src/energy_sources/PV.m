%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Based on class excersice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef PV
    % PV: Photovoltaic (PV) module class for creating PV module instances.
    %   It requires the provision of four parameters for instantiating 
    %   a PV object:
    %
    %   Parameters:
    %   1. efficiencyRef: Module efficiency in test condition
    %   2. temperatureRef: Module temperature in test condition (°C)
    %   3. betta: Module temperature coefficient of power (%/°C)
    %   4. surfaceArea: Module surface area (m^2)
    %
    %   Methods:
    %   - PV: Constructor method for creating an instance of the PV class.
    %   - PVefficiency: Computes the efficiency of a PV module at a given temperature.
    %   - powerOutPutFree: Computes the power output and temperature of a free-standing PV module.
    %   - powerOutPutBuilding: Computes the power output and temperature of a PV module in a building.
    %
    properties
        efficiencyRef
        temperatureRef
        betta
        surfaceArea
    end

    methods
        function obj = PV(efficiencyRef,temperatureRef,betta,surfaceArea)
            % PV: Constructor method for creating an instance of the PV class.
            %
            % Parameters:
            %   efficiencyRef: Module efficiency in test condition
            %   temperatureRef: Module temperature in test condition (°C)
            %   betta: Module temperature coefficient of power (%/°C)
            %   surfaceArea: Module surface area (m^2)
            %
            % Returns:
            %   obj: An instance of the PV class.
            %
            obj.efficiencyRef = efficiencyRef;
            obj.temperatureRef = temperatureRef;
            obj.betta = betta/100;
            obj.surfaceArea=surfaceArea;
        end

        function efficiency = PVefficiency(obj,temperature)
            % PVefficiency: Computes the efficiency of a PV module at a given temperature.
            %
            % Parameters:
            %   temperature: Temperature at which to compute efficiency (°C)
            %
            % Returns:
            %   efficiency: Efficiency of the PV module at the provided temperature.
            %
            efficiency = obj.efficiencyRef*(1+obj.betta*(temperature-obj.temperatureRef));
        end

        function [N, Tm] = powerOutPutFree(obj,radiation, ambientTemperature, windSpeed)
            % powerOutPutFree: Computes the power output and temperature of a free-standing PV module.
            %
            % Inputs:
            %   radiation: Solar radiation (W/m^2)
            %   ambientTemperature: Ambient temperature (°C)
            %   windSpeed: Wind velocity (m/s)
            %
            % Returns:
            %   N: Module power output (W)
            %   Tm: Module temperature (°C)
            %
            Ul = 2*(5.7+3.8*windSpeed);  % Heat transfer coefficient for free standing
            Tm = (-obj.efficiencyRef*radiation.*(1-obj.betta*obj.temperatureRef)...
                +Ul.*ambientTemperature+radiation)./(Ul+obj.efficiencyRef*radiation.*obj.betta); % Module temperature
            N = PVefficiency(obj,Tm).*radiation*obj.surfaceArea; % Module power output
        end

        function [N, Tm] = powerOutPutBuilding(obj,radiation, ambientTemperature, windSpeed)
            % powerOutPutBuilding: Computes the power output and temperature of a PV module in a building.
            %   
            % Inputs:
            %   radiation: Solar radiation (W/m^2)
            %   ambientTemperature: Ambient temperature (°C)
            %   windSpeed: Wind velocity (m/s)
            %
            % Returns:
            %   N: Module power output (W)
            %   Tm: Module temperature (°C)
            %
            Ul = (5.7+3.8*windSpeed);
            Tm = (-obj.efficiencyRef*radiation.*(1-obj.betta*obj.temperatureRef)...
                +Ul.*ambientTemperature+radiation)./(Ul+obj.efficiencyRef*radiation.*obj.betta);
            N = PVefficiency(obj,Tm).*radiation*obj.surfaceArea;
        end
    end
end

