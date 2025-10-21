classdef OmittedStimulus < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
    properties
        %times in ms
        preTime = 500	        % Spot leading duration (ms)
        singleStimTime = 40 	% Spot duration (ms)
        tailTime = 1000	        % Spot trailing duration (ms)
        numberOfStims = 16      % OSR sequence: 16 dark flashes @12Hz
        stimulusInterval = 40   % Separation between flashes (ms)
        skipStim = 0            % Index of the flash to be skipped (0: skip none, use even numbers if combined with Big-Small)
        bigSmall = false        % Alternate intensity 100%-50% (the skipped flash won't alternate)
        intensity = 1           % Stimulus intensity (either 0 or 1 & the opposite for background)
        spotSize = 340;         % Spot diameter (um)
        numberOfEpochs = 1;     % Repetitions of the flash sequence
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
    
    properties (Dependent)
        stimTime
    end
    
    methods
        
        function prepareRun(obj)
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
        end
        
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            epoch.addParameter('epochIdx', obj.epochIdx);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3); 
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
                    if obj.skipStim ~= 0 && i == obj.skipStim && obj.bigSmall == false
                        i = i + 1;
                    end
                    startTime = (preTime + (i-1)*(stimTime+stimInterval))*1e-3;
                    endTime = (preTime + i*stimTime + (i-1)*stimInterval)*1e-3;
                    stim(end+1) = (state.time > startTime && state.time<=endTime);
                    if (obj.skipStim == 0) || (obj.skipStim ~= 0 && i ~= obj.skipStim)
                        if obj.bigSmall && mod(i,2) == 0
                            stim(end) = stim(end)*0.5;
                        end
                    end
                end
                c = max(stim);
            end
            controller = stage.builtin.controllers.PropertyController(stageObject, 'opacity', ...
                @(s)turnOnDuringStim(s, obj.preTime, obj.singleStimTime, obj.numberOfStims, obj.stimulusInterval));
            p.addController(controller);
            
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
        function stimTime = get.stimTime(obj)
            stimTime = obj.numberOfStims*obj.singleStimTime + (obj.numberOfStims-1)*obj.stimulusInterval;
        end
        
    end
    
end