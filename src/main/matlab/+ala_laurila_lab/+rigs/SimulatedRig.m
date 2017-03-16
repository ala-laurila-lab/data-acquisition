classdef SimulatedRig < ala_laurila_lab.rigs.AaltoPatchRig
    
    methods
        
        function obj = SimulatedRig()
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaSimulationDaqController();
            obj = obj@ala_laurila_lab.rigs.AaltoPatchRig(daq);
            
            rigProperty = ala_laurila_lab.factory.getInstance('rigProperty');
            rigProperty.testMode = true;
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
            mockedLcr = ala_laurila_lab.devices.MockedLightCrafterDevice();
            obj.addDevice(mockedLcr);
        end
        
        function addOptometer(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            
            optometer = UnitConvertingDevice('Optometer', 'V').bindStream(daq.getStream('ai4'));
            obj.addDevice(optometer);
        end
    end
    
end

