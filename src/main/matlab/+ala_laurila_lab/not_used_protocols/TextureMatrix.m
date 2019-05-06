classdef TextureMatrix < sa_labs.protocols.stage.TextureMatrix  & sa_labs.common.ProtocolLogger
    
    % This file contains the protocol documentation
    % The actual protocol lives in lib/sa-labs-extension/src/main/matlab/+sa_labs/+protocols/+stage
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.stage.TextureMatrix(obj);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableHeader('blurSigma');
            DaqLogger.addLogTableHeader('randomSeed');
            DaqLogger.addLogTableHeader('halfMaxScale');
            DaqLogger.addLogTableHeader('negativeImage');
            obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.stage.TextureMatrix(obj, epoch);
            import sa_labs.common.DaqLogger;
            DaqLogger.addLogTableColumn('blurSigma', epoch.parameters('blurSigma'));
            DaqLogger.addLogTableColumn('randomSeed', epoch.parameters('randomSeed'));
            DaqLogger.addLogTableColumn('halfMaxScale', epoch.parameters('halfMaxScale'));
            DaqLogger.addLogTableColumn('negativeImage', epoch.parameters('negativeImage'));
            obj.logPrepareEpoch(epoch);
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.stage.TextureMatrix(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.stage.TextureMatrix(obj);
            obj.logCompleteRun();
        end
    end
end

