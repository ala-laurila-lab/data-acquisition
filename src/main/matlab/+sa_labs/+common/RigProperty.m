classdef RigProperty < handle & mdepin.Bean
    
    properties
        rigDescription
        testMode
        numberOfChannels
    end
    
    methods
        
        function obj = RigProperty(config)
            obj = obj@mdepin.Bean(config);
            obj.testMode = false;
        end
    end
end

