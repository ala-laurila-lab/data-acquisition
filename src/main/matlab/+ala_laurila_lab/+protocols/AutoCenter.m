classdef AutoCenter < sa_labs.protocols.stage.AutoCenter & sa_labs.common.ProtocolLogger
    
    % This file contains the protocol documentation
    % The actual protocol lives in lib/sa-labs-extension/src/main/matlab/+sa_labs/+protocols/+stage
    
    properties (Hidden)
        startDateTime
    end
    
    methods
        
        function prepareRun(obj)
            obj.startDateTime = datetime;
            prepareRun@sa_labs.protocols.stage.AutoCenter(obj);
          
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableHeader('stimTime');
            DaqLogger.addLogTableHeader('values');  
            DaqLogger.addLogTableHeader('Total Time(s)');  
            obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.stage.AutoCenter(obj, epoch);
            obj.logPrepareEpoch(epoch);
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.stage.AutoCenter(obj, epoch);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableColumn('stimTime', obj.stimTime);
            DaqLogger.addLogTableColumn('values', obj.values);
            DaqLogger.addLogTableColumn('Total Time(s)', seconds(datetime - obj.startDateTime));
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.stage.AutoCenter(obj);
            obj.logCompleteRun();
        end
    end
end

