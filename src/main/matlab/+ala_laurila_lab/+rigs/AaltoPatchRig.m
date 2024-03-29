classdef AaltoPatchRig < symphonyui.core.descriptions.RigDescription
    
    properties
        micronsPerPixel = 1.8
        frameTrackerPosition = [40, 40]
        frameTrackerSize = [80, 80]
        
        calibrationDataUnit = 'aalto-patch-rig-data'
        calibrationLogUnit = 'aalto-patch-rig-log'
        
        firstFilterWheelNdfValues = [1, 2, 3, 4, 5, 6];
        firstFilterWheelAttentuationValues = [1e-1, 1e-2, 1e-3, 1e-4, 1, 1];
        firstFilterWheelDefaultValue = 4;
        
        secondFilterWheelNdfValues = [1, 2, 3, 4, 5, 6];
        secondFilterWheelAttentuationValues = [1, 1, 1e-3, 1e-4, 1, 1];
        secondFilterWheelDefaultValue = 4;
        
        projectorColorMode = 'standard'
        
        hiddenProperties = {'meanLevel1', 'meanLevel2', 'contrast1', 'contrast2', ...
            'greenLED', 'redLED', 'uvLED', 'colorPattern2', 'colorPattern3', 'primaryObjectPattern',...
            'secondaryObjectPattern', 'backgroundPattern', 'colorCombinationMode', 'RstarIntensity1',...
            'MstarIntensity1', 'SstarIntensity1', 'RstarIntensity2', 'MstarIntensity2', 'SstarIntensity2', 'colorPattern1'};
    end
    
    methods
        
        function obj = AaltoPatchRig(daq)
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            if nargin < 1
                daq = HekaDaqController(HekaDeviceType.ITC1600);
            end
            obj.daqController = daq;
            
            % @deperecated rig property device replace with rigs.RigProperty
            propertyDevice = sa_labs.devices.RigPropertyDevice('test', false);
            obj.addDevice(propertyDevice);
            propertyDevice.addConfigurationSetting('enableRstarConversion', false, 'isReadOnly', true);
            
            rigProperty = sa_labs.factory.getInstance('rigProperty');
            rigProperty.rigDescription = obj;
            rigProperty.numberOfChannels = 4;
            
            obj.prepareRigDescription();
        end
        
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addRigSwitches();
            obj.addOscilloscopeTrigger();
            obj.addFilterWheels();
            obj.addTempratureController();          
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
        
        function addTempratureController(obj)
            import symphonyui.builtin.devices.*;
            daq = obj.daqController;
            
            temperature = UnitConvertingDevice('Temperature Controller', 'V', 'manufacturer', 'Warner Instruments').bindStream(daq.getStream('ai7'));
            obj.addDevice(temperature);
        end
        
        function addAmplifier(obj)
            
            import symphonyui.builtin.devices.*;
            daq = obj.daqController;
            
            amp1 = MultiClampDevice('Amp1', 1, 836019).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);
            
            amp2 = MultiClampDevice('Amp2', 2, 836019).bindStream(daq.getStream('ao1')).bindStream(daq.getStream('ai1'));
            obj.addDevice(amp2);
            
            amp3 = MultiClampDevice('Amp3', 2, 836392).bindStream(daq.getStream('ao2')).bindStream(daq.getStream('ai2'));
            obj.addDevice(amp3);
            
            amp4 = MultiClampDevice('Amp4', 2, 836392).bindStream(daq.getStream('ao3')).bindStream(daq.getStream('ai3'));
            obj.addDevice(amp4);
        end
        
        function addProjector(obj)
            lightCrafter = sa_labs.devices.LightCrafterDevice('micronsPerPixel', obj.micronsPerPixel);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition);
            lightCrafter.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize);
            lightCrafter.addConfigurationSetting('ndfCalibrationLedInput', [100, 100, 100]);
            lightCrafter.addConfigurationSetting('recommendedMaxLedCurrent', 160);
            obj.addDevice(lightCrafter);
        end
        
        function addRigSwitches(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            
            rigSwitch1 = UnitConvertingDevice('rigSwitch1', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch1, 0);
            obj.addDevice(rigSwitch1);
            
            rigSwitch2 = UnitConvertingDevice('rigSwitch2', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch2, 1);
            obj.addDevice(rigSwitch2);
            
            rigSwitch3 = UnitConvertingDevice('rigSwitch3', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch3, 2);
            obj.addDevice(rigSwitch3);
            
            rigSwitch4 = UnitConvertingDevice('rigSwitch4', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch4, 3);
            obj.addDevice(rigSwitch4);
        end
        
        function addOscilloscopeTrigger(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            
            trigger = UnitConvertingDevice('Oscilloscope Trigger', Measurement.UNITLESS).bindStream(daq.getStream('doport0'));
            daq.getStream('doport0').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
        end
        
        function addFilterWheels(obj)
            firstNdfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice('COM11', 1);
            firstNdfWheel.addConfigurationSetting('filterWheelNdfValues', obj.firstFilterWheelNdfValues);
            firstNdfWheel.addResource('filterWheelAttenuationValues', obj.firstFilterWheelAttentuationValues);
            firstNdfWheel.addResource('defaultNdfValue', obj.firstFilterWheelDefaultValue);
            obj.addDevice(firstNdfWheel);
            
            secondNdfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice('COM12', 2);
            secondNdfWheel.addConfigurationSetting('filterWheelNdfValues', obj.secondFilterWheelNdfValues);
            secondNdfWheel.addResource('filterWheelAttenuationValues', obj.secondFilterWheelAttentuationValues);
            secondNdfWheel.addResource('defaultNdfValue', obj.secondFilterWheelDefaultValue);
            obj.addDevice(secondNdfWheel);
        end
        
        function service = getCalibrationService(obj)
            service = sa_labs.factory.getInstance('calibrationService');
            service.dataPersistence = obj.calibrationDataUnit;
            service.logPersistence = obj.calibrationLogUnit;
        end
        
        function [rstar, mstar, sstar] = getIsomerizations(obj, intensity, parameter)
            
            rstar = [];
            mstar = [];
            sstar = [];

        end
        
        function tf = toBeHidden(obj, name)
            tf = ismember(name,  obj.hiddenProperties);
        end

    end
end

