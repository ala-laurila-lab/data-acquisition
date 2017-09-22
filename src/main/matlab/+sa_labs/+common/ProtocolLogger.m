classdef ProtocolLogger < handle
    
    properties (Hidden)
        currentEpochNumber = 0
    end

    methods (Access = protected)
        
        function logPrepareRun(obj)
            import sa_labs.common.DaqLogger;
            obj.currentEpochNumber = 0;
            
            DaqLogger.log('Preparing epoch ...');           
            DaqLogger.log(sprintf('%s ', evalc('disp(obj)')));

            DaqLogger.addLogTableHeader('1-(E)Epoch-No');
            DaqLogger.addLogTableHeader('2-(C)Epoch-No');
            DaqLogger.addLogTableHeader('3-(P)Epoch-No');
            DaqLogger.log(DaqLogger.getHeader());
        end
        
        function logPrepareEpoch(obj, epoch)
            if obj.hasValidPersistor()
                epochNumber = obj.addRunningEpochNumber();
                epoch.addParameter('epochNumber', epochNumber);
                epochNumberByExp = obj.addRunningEpochNumberByExperiment();
                obj.currentEpochNumber = obj.currentEpochNumber + 1;
                
                import sa_labs.common.DaqLogger;
                DaqLogger.addLogTableColumn('1-(E)Epoch-No', epochNumberByExp);
                DaqLogger.addLogTableColumn('2-(C)Epoch-No', epochNumber);
                DaqLogger.addLogTableColumn('3-(P)Epoch-No', obj.currentEpochNumber);
            end
        end
        
        function logCompleteEpoch(obj, epoch)
            import sa_labs.common.DaqLogger;
            if obj.hasValidPersistor()
                DaqLogger.log(DaqLogger.getCurrentRow());
            end
        end
        
        function logCompleteRun(obj)
            import sa_labs.common.DaqLogger;
            DaqLogger.flushTable();
        end
    end
end

