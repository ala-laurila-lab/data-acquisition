classdef DecrementIncrement < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
    properties
        %times in ms
        preTime = 500	% Spot leading duration (ms)
        stimTime = 16.7	% Spot duration (ms)
        tailTime = 1000	% Spot trailing duration (ms)
        
        spotSize = 170; % um
        numberOfEpochs = 30;
        decrementOnly = false;
        randomOrdering = true;         % ramdom presentation order
    end
    
    properties (Hidden)
        version = 1
        order
        intensity
        epochIdx
        numberOfCombinations
        
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'epochIdx';
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function prepareRun(obj)
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            obj.numberOfCombinations = 1 + ~obj.decrementOnly;
            obj.order = 1:obj.numberOfCombinations;
            
        end
        
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
            
            % Randomize the order if this is a new cycle
            index = mod(obj.numEpochsPrepared, obj.numberOfCombinations) + 1;
            if index == 1 && obj.randomOrdering
                obj.order = obj.order(randperm(obj.numberOfCombinations)); 
            end
            
            obj.epochIdx = obj.order(index);
            if obj.epochIdx == 1
                obj.intensity = 0;
            else
                obj.intensity = 2*obj.meanLevel;
            end
            
            epoch.addParameter('intensity', obj.intensity);
            epoch.addParameter('epochIdx', obj.epochIdx);
           
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            obj.setOnDuringStimController(p, spot);
            
        end
        
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
    end
    
end