classdef WhiteNoiseFlicker < sa_labs.protocols.stage.WhiteNoiseFlicker  & sa_labs.common.ProtocolLogger
    
    % This file contains the protocol documentation
    % The actual protocol lives in lib/sa-labs-extension/src/main/matlab/+sa_labs/+protocols/+stage
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.stage.WhiteNoiseFlicker(obj);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableHeader('randSeed');
            obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.stage.WhiteNoiseFlicker(obj, epoch);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableColumn('randSeed', epoch.parameters('randSeed'));
            obj.logPrepareEpoch(epoch);
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.stage.WhiteNoiseFlicker(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.stage.WhiteNoiseFlicker(obj);
            obj.logCompleteRun();
        end
    end
end

