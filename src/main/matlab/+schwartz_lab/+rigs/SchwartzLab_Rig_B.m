classdef SchwartzLab_Rig_B < schwartz_lab.rigs.SchwartzLab_Rig_Base
    
    properties
        % properties not accessible here; have to be fed into a device to work
        rigName = 'Schwartz Lab Rig B';
        testMode = false;
        filterWheelNdfValues = [0, 2, 3, 4, 5, 6];
        filterWheelAttenuationValues = [1.0, 0.0076, 6.23E-4, 6.93E-5, 8.32E-6, 1.0E-6];
        filterWheelDefaultValue = 5;
             
        micronsPerPixel = 2.3;
        frameTrackerPosition = [90,240];
        frameTrackerSize = [50,50];
        filterWheelComPort = 'COM12';
        orientation = [false, false];
        angleOffset = 270;

        fitBlue = [7.89617359432192e-12 -4.46160989505515e-09 1.32776088533859e-06 1.96157899559780e-05];
        fitGreen =[4.432E-12, -3.514E-9, 1.315E-6, 1.345E-5];
        fitUV = [];
        %PREVIOUS fitBlue = [7.603E-12, -6.603E-9, 2.133E-6, 3.398E-5];
        %PREVIOUS fitBlue = [1.0791E-11 -6.3562E-09 1.8909E-06 2.8196E-05];
        
        projectorColorMode = 'standard';
        numberOfAmplifiers = 1;
    end
    
    methods
        
        function obj = SchwartzLab_Rig_B()
            obj.initializeRig();
        end

    end
    
end

