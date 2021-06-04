classdef OptometerUDTS470 < handle
    
    properties (Constant)
        OUTPUT_MAX = 2500 % mV
        RNG_MAX = 10^4
        RNG_MIN = 10^4
        RNG_STEP_MULTIPLIER = 10
        MICROWATT_PER_MILLIVOLT = 1/100;
    end
    
    properties
        range
    end
    
    methods
        
        function obj = OptometerUDTS470(initialrange)
            if nargin < 1
                initialrange = obj.RNG_MAX;
            end
            obj.range = initialrange;
        end
        
        function increaseRange(obj)
            obj.range = obj.range * obj.RNG_STEP_MULTIPLIER;
        end
        
        function decreaseRange(obj)
            obj.range = obj.range / obj.RNG_STEP_MULTIPLIER;
        end
        
        function set.range(obj, range)
            if range == obj.range
                return;
            end
            
            rangeExponent = single(log(range) / log(obj.RNG_STEP_MULTIPLIER));
            if mod(rangeExponent, 1) ~= 0
                error('Bad gain value.');
            end
            
            if range > obj.RNG_MAX || range < obj.RNG_MIN
                error('Requested range is out of bounds.');  
            end
            
            presenter = appbox.MessagePresenter( ...
                ['Set optometer range to MAN X ' num2str(obj.RNG_STEP_MULTIPLIER) '^' num2str(rangeExponent)], ...
                'Optometer', ...
                'button1', 'OK');
            presenter.goWaitStop();
            obj.range = range;
        end
        
    end
    
end