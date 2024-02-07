%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Based on class excersice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef windTurbine
    % windTurbine: Wind turbine class for creating wind turbine instances.
    %   It requires the provision of five parameters for instantiating 
    %   a wind turbine object:
    %
    %   Parameters:
    %   1. startingWindVelocity: minimum wind velocity (m/s) for starting
    %   wind turbine
    %   2. nominalWindVelocity: wind velocity (m/s) when a wind turbine has
    %   maximum power
    %   3. maximumWindVelocity: maximum wind velocity (m/s), when wind
    %   turbine is stopping
    %   4. maximumPower: maximum power (W) of a wind turbine
    %   5. coefficent1, coefficent2: Coefficients used in the power calculation
    %
    %   Methods:
    %   - windTurbine: Constructor method for creating an instance of the windTurbine class.
    %   - calculatePower: Computes the power output of the wind turbine for a given wind velocity.
    %
    properties
        startingWindVelocity
        nominalWindVelocity
        maximumWindVelocity
        maximumPower
        coefficent1
        coefficent2
    end

    methods
        function obj = windTurbine(startingWindVelocity, nominalWindVelocity, ...
                maximumWindVelocity, maximumPower)
            % windTurbine: Construct a wind turbine instance.
            %
            % Parameters:
            %   startingWindVelocity: minimum wind velocity (m/s) for starting wind turbine
            %   nominalWindVelocity: wind velocity (m/s) when a wind turbine has maximum power
            %   maximumWindVelocity: maximum wind velocity (m/s), when wind turbine is stopping
            %   maximumPower: maximum power (W) of a wind turbine
            %
            % Returns:
            %   obj: An instance of the windTurbine class.
            %
            obj.startingWindVelocity = startingWindVelocity;
            obj.nominalWindVelocity = nominalWindVelocity;
            obj.maximumWindVelocity = maximumWindVelocity;
            obj.maximumPower = maximumPower;

            obj.coefficent1 = obj.maximumPower/(obj.nominalWindVelocity^3 ...
                -obj.startingWindVelocity^3);
            obj.coefficent2 = -obj.coefficent1*obj.startingWindVelocity^3;
        end

        function power = calculatePower(obj,windVelocity)
            % calculatePower: Calculate power output for given wind velocity.
            %
            % Parameters:
            %   windVelocity: Wind velocity for which power is calculated.
            %
            % Returns:
            %   power: Power output corresponding to the input wind velocity.
            %
            power = zeros(length(windVelocity),1);

            power(windVelocity > obj.startingWindVelocity & ...
                windVelocity < obj.nominalWindVelocity) = obj.coefficent1*...
                windVelocity(windVelocity > obj.startingWindVelocity & ...
                windVelocity < obj.nominalWindVelocity).^3+obj.coefficent2;

            power(windVelocity >= obj.nominalWindVelocity & ...
                windVelocity < obj.maximumWindVelocity) = obj.maximumPower;

        end
    end
end

