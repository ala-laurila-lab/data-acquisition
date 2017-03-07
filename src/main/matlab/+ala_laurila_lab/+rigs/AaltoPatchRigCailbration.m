classdef AaltoPatchRigCailbration < ala_laurila_lab.AaltoPatchRig
      
    methods
        
        function obj = AaltoPatchRigCailbration()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaDaqController(HekaDeviceType.ITC1600);
            obj.daqController = daq;
            
            lightCrafter = sa_labs.devices.LightCrafterDevice('micronsPerPixel', obj.micronsPerPixel);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition);
            lightCrafter.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize);
 
            obj.addDevice(lightCrafter);
        end
    end
end

