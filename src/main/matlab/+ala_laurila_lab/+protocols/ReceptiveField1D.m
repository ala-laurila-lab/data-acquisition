classdef ReceptiveField1D < sa_labs.protocols.stage.ReceptiveField1D  & sa_labs.common.ProtocolLogger
    
    % This file contains the protocol documentation
    % The actual protocol lives in lib/sa-labs-extension/src/main/matlab/+sa_labs/+protocols/+stage
    
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.stage.ReceptiveField1D(obj);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableHeader('positionX');
            DaqLogger.addLogTableHeader('positionY');
            obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.stage.ReceptiveField1D(obj, epoch);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableColumn('positionX', epoch.parameters('positionX'));
            DaqLogger.addLogTableColumn('positionY', epoch.parameters('positionY'));
            obj.logPrepareEpoch(epoch);
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.stage.ReceptiveField1D(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.stage.ReceptiveField1D(obj);
            obj.logCompleteRun();
        end
    end
end

