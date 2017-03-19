classdef AaltoPatchRig < symphonyui.core.descriptions.RigDescription
    
    properties
        micronsPerPixel = 1.869
        frameTrackerPosition = [40, 40]
        frameTrackerSize = [80, 80]
        
        calibrationDataUnit = 'aalto-patch-rig-data'
        calibrationLogUnit = 'aalto-patch-rig-log'
        
        filterWheelNdfValues = [1, 2, 3, 4, 5, 6];
        filterWheelAttenuationValues = [0.0105, 8.0057e-05, 6.5631e-06, 5.5485e-07, 5.5485e-08, 5.5485e-09];
        filterWheelDefaultValue = 3;
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
            
            obj.prepareRigDescription();
        end
        
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addRigSwitches();
            obj.addOscilloscopeTrigger();
            obj.addFilterWheel();
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
        
        function addFilterWheel(obj)
            ndfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice('COM11');
            ndfWheel.setConfigurationSetting('filterWheelNdfValues', obj.filterWheelNdfValues);
            ndfWheel.addResource('filterWheelAttenuationValues', obj.filterWheelAttenuationValues);
            ndfWheel.addResource('defaultNdfValue', obj.filterWheelDefaultValue);
            
            obj.addDevice(ndfWheel);
        end
        
        function service = getCalibrationService(obj)
            service = sa_labs.factory.getInstance('calibrationService');
            service.dataPersistence = obj.calibrationDataUnit;
            service.logPersistence = obj.calibrationLogUnit;
        end
        
        function [rstar, mstar, sstar] = convertIntensityToIsomerizations(obj, parameter, mouse)
            import ala_laurila_lab.*;
            service = obj.getCalibrationService;
            
            powerPerUnitArea = service.getIntensityMeasurement(parameter.ledType).getPowerPerUnitArea();
            spectrum = service.getSpectralMeasurement(parameter.ledType);
            ndf = service.getNDFMeasurement(parameter.ndf);
            linearity = service.getLinearityByStimulsDuration(parameter.duration, parameter.ledType);
            
            powerSpectrumPerArea = spectrum.getNormalizedPowerSpectrum() * powerPerUnitArea;
            flux = linearity.getFluxByInput(parameter.ledCurrent, 'normalized', true);
            trans =  10^(-ndf.opticalDensity);
            
            rstarPerSecond = util.photonToIsomerisation(powerSpectrumPerArea, spectrum.wavelength, mouse.LAMDA_MAX_ROD, mouse.ROD_PHOTORECEPTOR_AREA);
            mstarPerSecond = util.photonToIsomerisation(powerSpectrumPerArea, spectrum.wavelength, mouse.LAMDA_MAX_MCONE, mouse.CONE_PHOTORECEPTOR_AREA);
            sstarPerSecond = util.photonToIsomerisation(powerSpectrumPerArea, spectrum.wavelength, mouse.LAMDA_MAX_SCONE, mouse.CONE_PHOTORECEPTOR_AREA);
            
            isomerisation = @(isomerisationPerSecond) flux * isomerisationPerSecond * trans * parameter.duration;
            rstar = isomerisation(rstarPerSecond);
            mstar = isomerisation(mstarPerSecond);
            sstar = isomerisation(sstarPerSecond);
        end
    end
end

