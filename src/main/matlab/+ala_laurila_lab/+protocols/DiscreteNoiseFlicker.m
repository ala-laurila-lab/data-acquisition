classdef DiscreteNoiseFlicker < sa_labs.protocols.StageProtocol  & sa_labs.common.ProtocolLogger
    
    properties
        preTime = 1000
        stimTime = 8000
        tailTime = 1000
        seedValue = 1
        framesPerStep = 6      % at 60Hz
        spotSize = 300         % stim size in microns, use rigConfig to set microns per pixel
        numberOfEpochs = 16     % number of cycles 
        numberOfIntensities = 5
    end
    
    properties (Hidden)
        version = 1; % Corrected preFrames when framePerStep > 1 
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'randSeed';
        waveVec
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function prepareRun(obj)
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            if ~ isempty(obj.rig.getDevices('LightCrafter'))
                patternRate = obj.rig.getDevice('LightCrafter').getPatternRate();
            end
            
            rng(obj.seedValue);
            nPatterns = ceil((obj.stimTime/1000) * (patternRate / obj.framesPerStep));
            pattern = repmat(1:obj.numberOfIntensities, 1, ceil(nPatterns / obj.numberOfIntensities));
            pattern = pattern(randperm(numel(pattern)));
            
            intensities = linspace(0, 2*obj.meanLevel, obj.numberOfIntensities);
            obj.waveVec = intensities(pattern);
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);

            %add seed parameter
            epoch.addParameter('randSeed', obj.seedValue);
            
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));  % convert to pixels
            spot.radiusY = spot.radiusX;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            if ~ isempty(obj.rig.getDevices('LightCrafter'))
                patternRate = obj.rig.getDevice('LightCrafter').getPatternRate();
            end
            
            preFrames = ceil((obj.preTime/1e3) * patternRate);
            
            function c = noiseStim(state, preTime, stimTime, preFrames, waveVec, frameStep, meanLevel)
                if state.frame > preFrames && state.time <= (preTime+stimTime) *1e-3
                    index = ceil((state.frame - preFrames) / frameStep);
                    c = waveVec(index);
                else
                    c = meanLevel;
                end
            end
            
            controller = stage.builtin.controllers.PropertyController(spot, 'color', @(s)noiseStim(s, obj.preTime, obj.stimTime, ...
                preFrames, obj.waveVec, obj.framesPerStep, obj.meanLevel));
            p.addController(controller);
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
    end
    
end