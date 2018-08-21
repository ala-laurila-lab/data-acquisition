classdef MovingSpot < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger

    properties
        preTime = 250                   % Bar leading duration (ms)
        tailTime = 250                  % Bar trailing duration (ms)
        intensity = 0.125                 % Bar light intensity (0-1)
        spotWidth = 200                 % Bar length size (um)
        spotHeight = 200                % Bar Width size (um)
        spotSpeed = 2000                % Bar speed (um / s)
        distance = 800                  % Bar distance (um)
        angleOffset = 0                 % Angle set offset (deg)
        numberOfAngles = 8              % Number of angles to stimulate
        numberOfCycles = 10              % Number of times through the set
    end
    
    properties (Hidden)
        version = 1                     % v1: copied and modified from MovingBar
        angles                          % angles for epochs, range between [0 - 360]
        spotAngle                       % direction for the current epoch @see prepareEpoch 
        
        responsePlotMode = 'polar';
        responsePlotSplitParameter = 'spotAngle';
    end
    
    properties (Dependent)
        stimTime                        % Bar duration (ms)
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
               
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            obj.angles = mod(round(0:360/obj.numberOfAngles:(360-.01)) + obj.angleOffset, 360);
            obj.logPrepareRun();
        end
        
        function prepareEpoch(obj, epoch)
            
            index = mod(obj.numEpochsPrepared, obj.numberOfAngles);
            if index == 0
                obj.angles = obj.angles(randperm(obj.numberOfAngles));
            end
            
            obj.spotAngle = obj.angles(index+1);
            epoch.addParameter('spotAngle', obj.spotAngle);

            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            obj.logPrepareEpoch(epoch);
        end        
        
        function p = createPresentation(obj)
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
                      
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotWidth / 2));
            spot.radiusY = round(obj.um2pix(obj.spotHeight / 2));
            spot.color = obj.intensity;
            spot.opacity = 1;
            p.addStimulus(spot);
            
            [~, pixelSpeed] = obj.um2pix(obj.spotSpeed);
            [~, pixelDistance] = obj.um2pix(obj.distance);
            xStep = pixelSpeed * cosd(obj.spotAngle);
            yStep = pixelSpeed * sind(obj.spotAngle);

            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            xStartPos = canvasSize(1)/2 - (pixelDistance / 2) * cosd(obj.spotAngle);
            yStartPos = canvasSize(2)/2 - (pixelDistance / 2) * sind(obj.spotAngle);
            
            function pos = movementController(state)
                pos = [NaN, NaN];
                t = state.time - obj.preTime * 1e-3;
                if t >= 0 && t < obj.stimTime * 1e-3
                    pos = [xStartPos + t * xStep, yStartPos + t * yStep];
                end
            end
            
            spotMovement = stage.builtin.controllers.PropertyController(spot, 'position', @(state)movementController(state));
            p.addController(spotMovement);
            
            % shared code for multi-pattern objects
            obj.setColorController(p, spot);
            
        end
            
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.StageProtocol(obj);
            obj.logCompleteRun();
        end
        
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * obj.numberOfAngles;
        end        

        function stimTime = get.stimTime(obj)
            t = obj.distance / obj.spotSpeed;
            stimTime = 1e3 * t;
        end
    end
    
end

