classdef batterySystem
    % batterySystem - A class for creating battery instances.
    %
    % Properties:
    %   maxPower      - Maximum power the battery can provide or absorb(W).
    %   capacity      - Total energy storage capacity of the battery(Wh).
    %   efficiency    - Efficiency of the energy conversion process.
    %   selfDischarge - Self-discharge rate (%/hour).
    %
    % Methods:
    %   batterySystem - Constructor method to create an instance of the class.
    %   calculateEnergy - Method to calculate energy and updated power based on
    %                     the power input, starting energy, and time step.
    %
    properties
        maxPower
        capacity
        efficiency
        selfDischarge
    end

    methods
        function obj = batterySystem(maxPower, ...
                capacity, efficiency, selfDischarge)
            % batterySystem - Constructor method to create an instance of the class.
            %
            %   Parameters:
            %       maxPower      - Maximum power(W)
            %       capacity      - Total energy storage capacity of the
            %       battery (Wh)
            %       efficiency    - Efficiency of the energy conversion process.
            %       selfDischarge - Self-discharge rate (%/month)
            %
            % Returns:
            %   obj: An instance of the batterySystem class.
            %
            obj.maxPower = maxPower;
            obj.capacity = capacity;
            obj.efficiency = efficiency;
            obj.selfDischarge = selfDischarge/100/30/24;
        end

        function [energy, power_out]= calculateEnergy(obj, power, ...
                startingEnergy)
            % calculateEnergy - Method to calculate energy and updated power.
            %
            %   Parameters:
            %       power          - Power input to the battery system.
            %       startingEnergy - Initial energy level in the battery.
            %
            %   Outputs:
            %       energy     - Updated energy level in the battery.
            %       power_out  - power output.
            timeStep = 1;

            if power > obj.maxPower
                power_out = obj.maxPower;
            elseif power < -obj.maxPower
                power_out = -obj.maxPower;
            else
                power_out = power;
            end

            if power_out > 0
                energy = (power_out*obj.efficiency ...
                    -exp(-obj.selfDischarge*timeStep)...
                    *(power_out*obj.efficiency ...
                    - startingEnergy*obj.selfDischarge))...
                    /obj.selfDischarge;
                if energy > obj.capacity
                    energy = obj.capacity;
                    power_out = (startingEnergy*obj.selfDischarge ...
                        - obj.capacity*obj.selfDischarge...
                        *exp(obj.selfDischarge*timeStep))/(obj.efficiency - ...
                        obj.efficiency*exp(obj.selfDischarge*timeStep));
                end
            elseif power_out < 0
                energy = (power_out...
                    -exp(-obj.selfDischarge*timeStep)...
                    *(power_out ...
                    - startingEnergy*obj.selfDischarge*obj.efficiency))...
                    /obj.selfDischarge/obj.efficiency;
                if energy < 0
                    energy = 0;
                    power_out = -startingEnergy*obj.selfDischarge*obj.efficiency...
                        /(exp(obj.selfDischarge*timeStep) - 1);
                end
            else
                energy = startingEnergy*exp(-obj.selfDischarge*timeStep);
            end

        end
    end
end
