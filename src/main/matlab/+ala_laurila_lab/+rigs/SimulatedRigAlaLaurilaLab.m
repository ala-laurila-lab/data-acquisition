classdef SimulatedRigAlaLaurilaLab < ala_laurila_lab.rigs.AaltoPatchRig
    
    methods
        
        function obj = SimulatedRigAlaLaurilaLab()
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaSimulationDaqController();
            obj = obj@ala_laurila_lab.rigs.AaltoPatchRig(daq);
            
            rigProperty = sa_labs.factory.getInstance('rigProperty');
            rigProperty.testMode = true;
            
            obj.calibrationDataUnit = 'simulated-rig-data';
            obj.calibrationLogUnit = 'simulated-rig-log';
        end
        
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addOptometer();
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
        
        function addProjector(obj)
            mockedLcr = ala_laurila_lab.devices.MockedLightCrafterDevice('micronsPerPixel', 1);
            mockedLcr.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition);
            mockedLcr.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize);
            mockedLcr.setConfigurationSetting('angleOffset', 0);
            obj.addDevice(mockedLcr);
        end
        
        function addOptometer(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            
            optometer = UnitConvertingDevice('Optometer', 'V').bindStream(daq.getStream('ai4'));
            obj.addDevice(optometer);
        end

         function [rstar, mstar, sstar] = getIsomerizations(obj, intensity, parameter)
            rstar = [];
            mstar = [];
            sstar = [];
            
            % validate all the parameter

            % validate the mouse arguments
        end
    end
    
end

