classdef AaltoPatchRigCailbration < ala_laurila_lab.rigs.AaltoPatchRigOneAmp
    
    methods
        
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addOscilloscopeTrigger();
            obj.addRigSwitches();
            obj.addFilterWheels();
            obj.addOptometer();
        end
        
        function addOptometer(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController ;
            optometer = UnitConvertingDevice('Optometer UDTS470', 'V').bindStream(daq.getStream('ai6'));
            obj.addDevice(optometer);
        end
    end
end

