classdef SimulatedRigWithUVProjector < ala_laurila_lab.rigs.AaltoPatchRig
    

    
    methods
        
        function obj = SimulatedRigWithUVProjector()
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaSimulationDaqController();
            obj = obj@ala_laurila_lab.rigs.AaltoPatchRig(daq);
            
            rigProperty = sa_labs.factory.getInstance('rigProperty');
            rigProperty.testMode = true;
            rigProperty.numberOfChannels = 2;
            rigProperty.rigDescription = obj;
            
            obj.calibrationDataUnit = 'simulated-rig-data';
            obj.calibrationLogUnit = 'simulated-rig-log';
            
            obj.hiddenProperties = {'meanLevel1', 'meanLevel2', 'contrast1', 'contrast2', ...
            'greenLED', 'redLED', 'uvLED', 'colorPattern2', 'colorPattern3', 'primaryObjectPattern',...
            'secondaryObjectPattern', 'backgroundPattern', 'colorCombinationMode', 'RstarIntensity1',...
            'MstarIntensity1', 'SstarIntensity1', 'RstarIntensity2', 'MstarIntensity2', 'SstarIntensity2', 'colorPattern1'};

        end
        
        function prepareRigDescription(obj)
            obj.addAmplifier();
            obj.addProjector();
            obj.addOptometer();
        end
        
        function addAmplifier(obj)
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            daq = obj.daqController;
            
            amp1 = MultiClampDevice('Amp1', 1, []).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);
            
            amp2 = MultiClampDevice('Amp2', 2, []).bindStream(daq.getStream('ao1')).bindStream(daq.getStream('ai1'));
            obj.addDevice(amp2);
        end
        
        function addOptometer(obj)
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            daq = obj.daqController;
            
            optometer = UnitConvertingDevice('Optometer', 'V').bindStream(daq.getStream('ai4'));
            obj.addDevice(optometer);
        end

         function [rstar, mstar, sstar] = getIsomerizations(obj, protocol, pattern)
            rstar = [];
            mstar = [];
            sstar = [];
            
            % validate all the parameter

            % validate the mouse arguments
         end
         
        function tf = toBeHidden(obj, name)
            tf = ismember(name,  obj.hiddenProperties);
        end
    end
    
end

