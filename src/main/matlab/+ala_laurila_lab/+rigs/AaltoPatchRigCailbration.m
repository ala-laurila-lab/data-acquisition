classdef AaltoPatchRigCailbration < ala_laurila_lab.rigs.AaltoPatchRig
    
    methods
        
        function prepareRigDescription(obj)
            obj.addProjector();
            obj.addRigSwitches();
            obj.addFilterWheel();
            obj.addOptometer();
        end
        
        function addOptometer(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            optometer = UnitConvertingDevice('Optometer', 'V').bindStream(daq.getStream('ai4'));
            obj.addDevice(optometer);
        end
    end
end

