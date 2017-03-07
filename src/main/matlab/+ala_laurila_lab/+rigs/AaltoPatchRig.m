classdef AaltoPatchRig < symphonyui.core.descriptions.RigDescription
    
    properties
        micronsPerPixel = 1.6
        frameTrackerPosition = [40, 40]
        frameTrackerSize = [80, 80]
        
        calibrationDataUnit = 'aalto-patch-rig-data'
        calibrationLogUnit = 'aalto-patch-rig-data'
    end
    
    methods
        
        function obj = AaltoPatchRig()
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController(HekaDeviceType.ITC1600);
            obj.daqController = daq;
            
            % TODO check alternative way to configure properties
            propertyDevice = sa_labs.devices.RigPropertyDevice('test', false);
            obj.addDevice(propertyDevice);
            propertyDevice.addConfigurationSetting('enableRstarConversion', false, 'isReadOnly', true);
            
            rigProperty = ala_laurila_lab.factory.getInstance('rigProperty');
            rigProperty.rigDescription = obj;
            
            
            amp1 = MultiClampDevice('Amp1', 1, 836019).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);
            
            amp2 = MultiClampDevice('Amp2', 2, 836019).bindStream(daq.getStream('ao1')).bindStream(daq.getStream('ai1'));
            obj.addDevice(amp2);
            
            amp3 = MultiClampDevice('Amp3', 2, 836392).bindStream(daq.getStream('ao2')).bindStream(daq.getStream('ai2'));
            obj.addDevice(amp3);
            
            amp4 = MultiClampDevice('Amp4', 2, 836392).bindStream(daq.getStream('ao3')).bindStream(daq.getStream('ai3'));
            obj.addDevice(amp4);
            
            lightCrafter = sa_labs.devices.LightCrafterDevice('micronsPerPixel', obj.micronsPerPixel);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition);
            lightCrafter.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize);
            obj.addDevice(lightCrafter);
            
            ndfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice('COM11');
            ndfWheel.setConfigurationSetting('filterWheelNdfValues', obj.filterWheelNdfValues);
            ndfWheel.addResource('filterWheelAttentuationValues', obj.filterWheelAttentuationValues);
            obj.addDevice(ndfWheel);
            
            trigger = UnitConvertingDevice('Oscilloscope Trigger', Measurement.UNITLESS).bindStream(daq.getStream('doport0'));
            daq.getStream('doport0').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
            
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
        
       function service = getCalibrationService(obj)
            service = ala_laurila_lab.factory.getInstance('calibrationService');
            service.dataPersistence = obj.calibrationDataUnit;
            service.logPersistence = obj.calibrationLogUnit;
       end
    end
end

