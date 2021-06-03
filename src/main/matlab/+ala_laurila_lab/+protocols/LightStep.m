classdef LightStep < sa_labs.protocols.stage.LightStep  & sa_labs.common.ProtocolLogger
    
    % This file contains the protocol documentation
    % The actual protocol lives in lib/sa-labs-extension/src/main/matlab/+sa_labs/+protocols/+stage
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.stage.LightStep(obj);
             obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.stage.LightStep(obj, epoch);
            obj.logPrepareEpoch(epoch);
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.stage.LightStep(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.stage.LightStep(obj);
            obj.logCompleteRun();
        end
    end
end

