classdef AaltoPatchRigCailbration < ala_laurila_lab.rigs.AaltoPatchRig
    
    methods
        
        function prepareRigDescription(obj)
            obj.addProjector();
            obj.addRigSwitches();
            obj.addFilterWheel();
        end
    end
end

