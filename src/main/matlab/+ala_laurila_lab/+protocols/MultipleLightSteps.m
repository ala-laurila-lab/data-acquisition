classdef MultipleLightSteps < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
    properties
        %times in ms
        preTime = 500	% Spot leading duration (ms)
        stimTime = 100	% Spot duration (ms)
        tailTime = 1500	% Spot trailing duration (ms)
        numberOfStims = 4
        stimulusInterval = 300
        
        intensity = 1
        spotSize = 200; % um
        numberOfEpochs = 30;
    end
    
    properties (Hidden)
        version = 1
        epochIdx = 1
        
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
            
        end
        
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
                
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            
            epoch.addParameter('epochIdx', obj.epochIdx);
            
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.numberOfStims*obj.stimTime + (obj.numberOfStims-1)*obj.stimulusInterval + obj.tailTime) * 1e-3);
            
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            obj.onController(p, spot);
            
        end
        
        function onController(obj, p, stageObject)
            function c = turnOnDuringStim(state, preTime, stimTime, nStims, stimInterval)
                stim = [];
                for i = 1:nStims
                    startTime = (preTime + (i-1)*(stimTime+stimInterval))*1e-3;
                    endTime = (preTime + i*stimTime + (i-1)*stimInterval)*1e-3;
                    stim(end+1) = (state.time > startTime && state.time<=endTime);
                end
                c = 1 * any(stim);
            end
            
            controller = stage.builtin.controllers.PropertyController(stageObject, 'opacity', ...
                @(s)turnOnDuringStim(s, obj.preTime, obj.stimTime, obj.numberOfStims, obj.stimulusInterval));
            p.addController(controller);
        end
        
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
    end
    
end