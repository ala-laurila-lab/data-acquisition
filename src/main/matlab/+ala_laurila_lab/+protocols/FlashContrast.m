classdef FlashContrast < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
        
    properties
        %times in ms
        preTime = 500                  % Spot leading duration (ms)
        stimTime = 16.7 
        tailTime = 1000                % Spot trailing duration (ms)
        spotSize = 200;                % spot diameter (um)
        numberOfRepetions = 30;        %
        numberOfContrasts = 3;
        scalingFactor = 2;
        smallestContrast = 0.25;          % Weber contrast
        decrement = true;
        randomOrdering = true;         % ramdom presentation order
        
    end
    
    properties (Hidden)
        version = 1                     % 
        order                           % current presetnation order
        combIdx
        contrasts
        contrast                        % current contrast
        intensity                       % current intensity
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'contrast';
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end

    methods
        
        function prepareRun(obj)
            obj.logPrepareRun();
            
            
            % Intensity variation
            nContrasts = obj.numberOfContrasts;
            obj.contrasts = obj.smallestContrast .* obj.scalingFactor.^(0:(nContrasts-1));
            
            % Start with the default order
            obj.order = 1:nContrasts;
            obj.combIdx = obj.order(1);
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
        end
            
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
            
            % Randomize the order if this is a new cycle
            index = mod(obj.numEpochsPrepared, obj.numberOfContrasts) + 1;
            if index == 1 && obj.randomOrdering
                obj.order = obj.order(randperm(obj.numberOfContrasts)); 
            end
            
            % Get the current position and intensity
            obj.combIdx = obj.order(index);
            
            if obj.decrement
                obj.intensity = obj.meanLevel*(1-obj.contrasts(obj.combIdx));
            else
                obj.intensity = obj.meanLevel*(1+obj.contrasts(obj.combIdx));
            end
            % Truncate
            if obj.intensity > 1
                obj.intensity = 1;
            elseif obj.intensity < 0
                obj.intensity = 0;
            end
            
            epoch.addParameter('combIdx', obj.combIdx);
            epoch.addParameter('contrast', obj.contrasts(obj.combIdx));
            epoch.addParameter('intensity', obj.intensity);
            
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
            spot.opacity = 1;
            p.addStimulus(spot);
            
            obj.changeStimIntensityController(p, spot);

        end
        
        function changeStimIntensityController(obj, p, stageObject)
            function c = changeDuringStim(state, preTime, stimTime, intensity, meanLevel)
                stim = (state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3);
                if stim
                    c = intensity;
                else
                    c = meanLevel;
                end
            end
            
            controller = stage.builtin.controllers.PropertyController(stageObject, 'color', ...
                @(s)changeDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            p.addController(controller);
        end
        
%         function stimTime = get.stimTime(obj)
%             stimTime = obj.stimTime;
%         end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfRepetions * obj.numberOfContrasts;
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

