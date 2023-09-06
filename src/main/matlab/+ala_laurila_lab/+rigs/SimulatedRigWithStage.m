classdef SimulatedRigWithStage < ala_laurila_lab.rigs.AaltoPatchRig
    
    properties(Constant)
        EMULATED_COM_PORT = 0
    end
    
    methods
        
        function obj = SimulatedRigWithStage()
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaSimulationDaqController();
            obj = obj@ala_laurila_lab.rigs.AaltoPatchRig(daq);
            
            rigProperty = sa_labs.factory.getInstance('rigProperty');
            rigProperty.testMode = true;
            rigProperty.numberOfChannels = 2;
            rigProperty.rigDescription = obj;
            
            obj.calibrationDataUnit = 'simulated-rig-data';
            obj.calibrationLogUnit = 'simulated-rig-log';
  
        end
        
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addOptometer();
            obj.addFilterWheels();            
            obj.addScanheadTrigger();
        end

        function addScanheadTrigger(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            scanhead = UnitConvertingDevice('Scanhead Trigger', Measurement.UNITLESS, 'manufacturer', 'Vidrio Technologies').bindStream(daq.getStream('doport0'));
            daq.getStream('doport0').setBitPosition(scanhead, 1);
            obj.addDevice(scanhead);
        end
        
        function addFilterWheels(obj)
            firstNdfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice(ala_laurila_lab.rigs.SimulatedRigWithStage.EMULATED_COM_PORT, 1);
            firstNdfWheel.addConfigurationSetting('filterWheelNdfValues', obj.firstFilterWheelNdfValues);
            firstNdfWheel.addResource('filterWheelAttenuationValues', obj.firstFilterWheelAttentuationValues);
            firstNdfWheel.addResource('defaultNdfValue', obj.firstFilterWheelDefaultValue);
            obj.addDevice(firstNdfWheel);
            
            secondNdfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice(ala_laurila_lab.rigs.SimulatedRigWithStage.EMULATED_COM_PORT, 2);
            secondNdfWheel.addConfigurationSetting('filterWheelNdfValues', obj.secondFilterWheelNdfValues);
            secondNdfWheel.addResource('filterWheelAttenuationValues', obj.secondFilterWheelAttentuationValues);
            secondNdfWheel.addResource('defaultNdfValue', obj.secondFilterWheelDefaultValue);
            obj.addDevice(secondNdfWheel);
        end
        
        function addAmplifier(obj)
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            daq = obj.daqController;
            
            amp1 = MultiClampDevice('Amp1', 1, []).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);
            
            amp2 = MultiClampDevice('Amp2', 2, []).bindStream(daq.getStream('ao1')).bindStream(daq.getStream('ai1'));
            obj.addDevice(amp2);
        end
        
        function addOptometer(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            
            optometer = UnitConvertingDevice('Optometer UDTS470', 'V').bindStream(daq.getStream('ai4'));
            obj.addDevice(optometer);
        end
        
        function [rstar, mstar, sstar] = getIsomerizations(obj, protocol, pattern)
            rstar = [];
            mstar = [];
            sstar = [];
            
            % validate all the parameter
            
            % validate the mouse arguments
        end
        
        function tf = toBeHidden(obj, name)
            tf = ismember(name,  obj.hiddenProperties);
        end
        
        function addProjector(obj)
            lightCrafter = ala_laurila_lab.devices.MockedLightCrafterDevice('micronsPerPixel', obj.micronsPerPixel);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition);
            lightCrafter.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize);
            lightCrafter.addConfigurationSetting('ndfCalibrationLedInput', [100, 100, 100])
%             lightCrafter.addConfigurationSetting('ledTypes', {'Blue
%             led'}); %config setting already exists, Zach 2023/03/15
            lightCrafter.addConfigurationSetting('recommendedMaxLedCurrent', 160);
            obj.addDevice(lightCrafter);
        end
    end
    
end

