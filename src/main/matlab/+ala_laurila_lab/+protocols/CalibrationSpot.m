classdef CalibrationSpot < sa_labs.protocols.StageProtocol
    
    properties
        spotSize = 500                  % spot size in (um)
    end
    
    properties(Hidden)
        intensity = 1.0                 % Cross light intensity (0-1)
        responsePlotMode = false
        numberOfEpochs = 1              % Number of epochs
        preTime = 500                   % Cross leading duration (ms)
        stimTime = 500                  % Cross duration (ms)
        tailTime = 0                    % Cross trailing duration (ms)
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@sa_labs.protocols.StageProtocol(obj);
            obj.NDF1 = 4;
            obj.NDF2 = 4;
            obj.blueLED = 100;
        end

        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            spot.opacity = 1;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@sa_labs.protocols.StageProtocol(obj, name);
            
            switch name
                case {'meanLevel'}
                    d.isHidden = true;
            end

        end
    end
    
end

