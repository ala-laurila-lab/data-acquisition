classdef AaltoPatchRigCailbration < ala_laurila_lab.AaltoPatchRig
    
    properties (Constant)
        PERSISTENCE_LOCATION = 'calibration-persistence.xml'
    end
    
    methods
        
        function obj = AaltoPatchRigCailbration()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController(HekaDeviceType.ITC1600);
            obj.daqController = daq;
            
            lightCrafter = fi.helsinki.biosci.ala_laurila.devices.LightCrafterDevice('micronsPerPixel', obj.micronsPerPixel);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition)
            lightCrafter.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize)
            obj.addDevice(lightCrafter);
        end
    end
    
    methods (Static)
        
        function service = getCalibrationService()
            persistent instance;
            
            if isempty(instance)
                path = ala_laurila_lab.rigs.AaltoPatchRigCailbration.PERSISTENCE_LOCATION;
                instance =  ala_laurila_lab.CalibrationService(path);
            end
            service = instance;
        end
        
        function updateSpectrum()
            import ala_laurila_lab.rigs.*;
            
            service = AaltoPatchRigCailbration.getCalibrationService();
            p = appbox.MessagePresenter()   
        end
    end
end

