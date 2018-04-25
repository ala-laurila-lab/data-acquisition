classdef AaltoPatchRigOneAmp < ala_laurila_lab.rigs.AaltoPatchRig

    methods
                
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addRigSwitches();
            obj.addOscilloscopeTrigger();
            obj.addFilterWheel();
            obj.addTempratureController();
        end
        
        function addAmplifier(obj)
            
            import symphonyui.builtin.devices.*;
            daq = obj.daqController;
            
            amp1 = MultiClampDevice('Amp1', 1, 836019).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);
            
            amp2 = MultiClampDevice('Amp2', 2, 836019).bindStream(daq.getStream('ao1')).bindStream(daq.getStream('ai1'));
            obj.addDevice(amp2);
            
            rigProperty = sa_labs.factory.getInstance('rigProperty');
            rigProperty.numberOfChannels = 2;
        end
        
         function [rstar, mstar, sstar] = getIsomerizations(obj, intensity, parameter)
            import ala_laurila_lab.*;
            rstar = [];
            mstar = [];
            sstar = [];
         end
    end
end

