classdef FlashingDots < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
        
    properties
        %times in ms
        preTime = 100                   % Spot leading duration (ms)
        stimTime = 300                  % Spot duration (ms)
        tailTime = 100                  % Spot trailing duration (ms)
        
        testWidth = 500;                % spot diameter (um)
        flashSize = 200;                 % spot diameter (um)
        intensities = [1];              % intensitites at each position
        numberOfCycles = 2              % repetitions of each pos/int
        randomOrdering = false;         % ramdom presentation order
        horizontalLine = false;         % false: circular / true: line
    end
    
    properties (Hidden)
        version = 1
        order                           % current presetnation order
        nFlashesPerCycle                % total number of flashes per cycle
        positionIntensityIds            % mapping to each pos/int
        positions                       % flash positions
        position                        % current position
        intensity                       % current intensity
        
        responsePlotMode = 'false';
        responsePlotSplitParameter = 'flashIdx';
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function prepareRun(obj)
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice('Optometer'));
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            % Generate points on a grid
            gridPositions = obj.flashSize:obj.flashSize:obj.testWidth;
            gridPositions = gridPositions - mean(gridPositions);
            [xCoord, yCoord] = meshgrid(gridPositions, gridPositions);
            obj.positions = [xCoord(:), yCoord(:)];
                
            % Create matrix whose rows uniquely identify each posiible
            % position/intensity combination
            nPositions = size(obj.positions, 1);
            [posIds, intIds] = ...
                meshgrid(1:nPositions, 1:length(obj.intensities));
            obj.positionIntensityIds = [posIds(:), intIds(:)];
            obj.nFlashesPerCycle = size(obj.positionIntensityIds, 1);
            
            % Start with the default order
            obj.order = 1:obj.nFlashesPerCycle;
            
        end
            
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
            
            % Randomize the order if this is a new cycle
            index = mod(obj.numEpochsPrepared, obj.nFlashesPerCycle) + 1;
            if index == 1 && obj.randomOrdering
                obj.order = obj.order(randperm(obj.nFlashesPerCycle)); 
            end
            
            % Get the current position and intensity
            rowIdx = obj.order(index);
            posIdx = obj.positionIntensityIds(rowIdx, 1);
            intIdx = obj.positionIntensityIds(rowIdx, 2);
            obj.position = obj.positions(posIdx, :);
            obj.intensity = obj.intensities(intIdx);
            
            epoch.addParameter('position', obj.position);
            epoch.addParameter('intensity', obj.intensity);
            epoch.addParameter('flashIdx', rowIdx);
            
            optometer = obj.rig.getDevice('Optometer');
            epoch.addResponse(optometer);
            
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
                        
        end     
      
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);

%             spot = stage.builtin.stimuli.Ellipse();
%             spot.radiusX = round(obj.um2pix(obj.flashSize / 2));
%             spot.radiusY = spot.radiusX;
            spot = stage.builtin.stimuli.Rectangle();
            spot.size = round([obj.um2pix(obj.flashSize), obj.um2pix(obj.flashSize)]);
            spot.color = obj.intensity;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2 + round(obj.um2pix(obj.position));
            spot.opacity = 1;
            p.addStimulus(spot);
            
            obj.setOnDuringStimController(p, spot);
            
            % shared code for multi-pattern objects
            obj.setColorController(p, spot);

        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * obj.nFlashesPerCycle;
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

