classdef OptometerUDTS470 < handle
    
    properties (Constant)
        OUTPUT_MAX = 2500 % mV
        GAIN_MAX = 10^10
        GAIN_MIN = 10^3
        GAIN_STEP_MULTIPLIER = 10
        MICROWATT_PER_MILLIVOLT = 1 / 100;
    end
    
    properties
        gain
    end
    
    methods
        
        function obj = OptometerUDTS470(initialGain)
            if nargin < 1
                initialGain = obj.GAIN_MIN;
            end
            obj.gain = initialGain;
        end
        
        function increaseGain(obj)
            obj.gain = obj.gain * obj.GAIN_STEP_MULTIPLIER;
        end
        
        function decreaseGain(obj)
            obj.gain = obj.gain / obj.GAIN_STEP_MULTIPLIER;
        end
        
        function set.gain(obj, gain)
            if gain == obj.gain
                return;
            end
            
            gainExponent = single(log(gain) / log(obj.GAIN_STEP_MULTIPLIER));
            if mod(gainExponent, 1) ~= 0
                error('Bad gain value.');
            end
            
            if gain > obj.GAIN_MAX || gain < obj.GAIN_MIN
                error('Requested gain is out of bounds.');  
            end
            
            presenter = appbox.MessagePresenter( ...
                ['Set optometer gain to ' num2str(obj.GAIN_STEP_MULTIPLIER) '^' num2str(gainExponent)], ...
                'Optometer', ...
                'button1', 'OK');
            presenter.goWaitStop();
            obj.gain = gain;
        end
        
    end
    
end