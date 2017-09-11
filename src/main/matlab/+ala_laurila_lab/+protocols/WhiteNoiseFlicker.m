classdef WhiteNoiseFlicker < sa_labs.protocols.StageProtocol
    
    properties
        preTime = 1000
        stimTime = 8000
        tailTime = 1000
        noiseSD = 0.2          % relative light intensity units
        framesPerStep = 1      % at 60Hz
        spotSize = 300         % stim size in microns, use rigConfig to set microns per pixel
        numberOfSeeds = 5      % number of random seeds
        numberOfCycles = 1     % number of cycles 
    end
    
    properties (Hidden)
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'randSeed';
        curSeed = 1;
        seeds
        waveVec
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            obj.seeds = zeros(1, obj.numberOfSeeds);
            
            for i = 1 : obj.numberOfSeeds 
                rng('shuffle');
                obj.seeds(i) = randi(10000);
            end
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            
            index = mod(obj.numEpochsPrepared, obj.numberOfSeeds) + 1;
            obj.curSeed =  obj.seeds(index);

            %add seed parameter
            epoch.addParameter('randSeed', obj.curSeed);
            disp(['Curseed = ' num2str(obj.curSeed)]);
            
            %set rand seed
            rng(obj.curSeed);
            
            if ~ isempty(obj.rig.getDevices('LightCrafter'))
                patternRate = obj.rig.getDevice('LightCrafter').getPatternRate();
            end
            
            nFrames = ceil((obj.stimTime/1000) * (patternRate / obj.framesPerStep));
            obj.waveVec = randn(1, nFrames);
            obj.waveVec = obj.waveVec .* obj.noiseSD; % set SD
            obj.waveVec = obj.waveVec + obj.meanLevel; % add mean
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
            
            preFrames = ceil((obj.preTime/1000) * (patternRate / obj.framesPerStep));
            
            function c = noiseStim(state, preTime, stimTime, preFrames, waveVec, frameStep, meanLevel)
                if state.time > preTime*1e-3 && state.time <= (preTime+stimTime) *1e-3
                    index = ceil((state.frame - preFrames) / frameStep);
                    c = waveVec(index);
                else
                    c = meanLevel;
                end
            end
            
            controller = stage.builtin.controllers.PropertyController(spot, 'color', @(s)noiseStim(s, obj.preTime, obj.stimTime, ...
                preFrames, obj.waveVec, obj.framesPerStep, obj.meanLevel));
            p.addController(controller);
                        
            obj.setOnDuringStimController(p, spot);
            
            % shared code for multi-pattern objects
            obj.setColorController(p, spot);
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * obj.numberOfSeeds;
        end
        
    end
    
end