classdef SpotsMultiSizeRF < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
        
    properties
        %times in ms
        preTime = 500                   % Spot leading duration (ms)
        stimTime = 16.7                 % flash duration
        tailTime = 1000                 % Spot trailing duration (ms)
        minSpotSize = 200;              % min spot diameter (um)
        maxSpotSize = 600;              % max spot diameter (um)
        nSizes = 3;                     % n spot sizes
        rfSigma = 80;                   % Assumed sigma for the spatial RF
        numberOfRepetions = 30;         % number of epochs for each size
        randomOrdering = false;         % ramdom presentation order
        
    end
    
    properties (Hidden)
        version = 1                     % removed spots of different size
        numberOfCombinations
        order                           % current presetnation order
        combIdx
        intensities
        intensity                       % current intensity
        spotSizes
        size                            % current size
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'combIdx';
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function prepareRun(obj)
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            % Determine spot sizes
            obj.spotSizes = linspace(obj.minSpotSize, obj.maxSpotSize, obj.nSizes);
            
            % Set the intensity based on the fraction of RF covered
            r2 = (obj.spotSizes./2).^2 / obj.rfSigma^2;
            rfFracs = 1 - exp(-r2/2);
            obj.intensities = rfFracs(1) ./ rfFracs;

            % Start with the default order
            obj.numberOfCombinations = numel(obj.intensities);
            obj.order = 1:obj.numberOfCombinations;
            
        end
            
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
            
            % Randomize the order if this is a new cycle
            index = mod(obj.numEpochsPrepared, obj.numberOfCombinations) + 1;
            if index == 1 && obj.randomOrdering
                obj.order = obj.order(randperm(obj.numberOfCombinations)); 
            end
            
            % Get the current position and intensity
            obj.combIdx = obj.order(index);
            obj.intensity = obj.intensities(obj.combIdx);
            obj.size = obj.spotSizes(obj.combIdx);
            
            epoch.addParameter('combIdx', obj.combIdx);
            epoch.addParameter('intensity', obj.intensity);
            epoch.addParameter('size', obj.size);
            
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
                        
        end     
      
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);

            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.size / 2));
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            spot.opacity = 1;
            p.addStimulus(spot);
            
            obj.setOnDuringStimController(p, spot);
            
            % shared code for multi-pattern objects
            obj.setColorController(p, spot);

        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfRepetions * obj.numberOfCombinations;
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.StageProtocol(obj);
            obj.logCompleteRun();
        end
    end
end

