classdef SpatialNoise < sa_labs.protocols.stage.SpatialNoise  & sa_labs.common.ProtocolLogger
    
    % This file contains the protocol documentation
    % The actual protocol lives in lib/sa-labs-extension/src/main/matlab/+sa_labs/+protocols/+stage
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.stage.SpatialNoise(obj);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableHeader('noiseSeed');
            obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.stage.SpatialNoise(obj, epoch);
            DaqLogger.addLogTableColumn('noiseSeed', obj.noiseSeed);
            obj.logPrepareEpoch(epoch);
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.stage.SpatialNoise(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.stage.SpatialNoise(obj);
            obj.logCompleteRun();
        end
    end
end

