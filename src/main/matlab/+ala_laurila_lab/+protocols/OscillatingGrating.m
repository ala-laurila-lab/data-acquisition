classdef OscillatingGrating < sa_labs.protocols.StageProtocol
        
    properties
        preTime = 500 % ms
        stimTime = 10000 % ms
        tailTime = 500 % ms

        spotSize = 300;
        frequency = 6;
        contrast = 0.5; 
        contrastMean = 0.5;
        nSpatialPeriods = 3;

        numberOfEpochs = uint16(10) % number of epochs to queue
    end

    properties (Hidden)
        version = 2;
        
        resolution = 40;
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'resolution';
        waveVec
        grating
        surround
    end
    
    properties (Dependent, Hidden)
        totalNumEpochs
    end
    
    methods
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);

            if ~ isempty(obj.rig.getDevices('LightCrafter'))
                patternRate = obj.rig.getDevice('LightCrafter').getPatternRate();
            end
            
            % Temporal oscillations
            nFrames = ceil((obj.stimTime/1000) * patternRate);
            amplitude = obj.contrast * obj.contrastMean;
            time = (1:nFrames) / patternRate;
            obj.waveVec = amplitude * sin(2*pi*obj.frequency*time);
            obj.waveVec = obj.waveVec; % add mean
            
            % Spatial grating
            barWidth = ceil(obj.resolution / obj.nSpatialPeriods / 2);
            obj.resolution = barWidth*2*obj.nSpatialPeriods;
            mask = repmat([true(1, barWidth), false(1, barWidth)], 1, obj.nSpatialPeriods);
            resTmp = linspace(-obj.spotSize/2, obj.spotSize/2, obj.resolution);
            [X1, X2] = meshgrid(resTmp, resTmp);
            radius = sqrt(X1.^2 + X2.^2);
            obj.grating = -1*ones(obj.resolution, obj.resolution);
            obj.grating(:, mask) = 1;
            obj.grating(radius > obj.spotSize/2) = 0;
            obj.surround = ones(obj.resolution, obj.resolution);
            obj.surround(radius <= obj.spotSize/2) = 0;
            
            epoch.addParameter('resolution', obj.resolution);
            epoch.addParameter('frequency', obj.frequency);
            epoch.addParameter('contrast', obj.contrast);
            epoch.addParameter('contrastMean', obj.contrastMean);
            epoch.addParameter('nSpatialPeriods', obj.nSpatialPeriods);
            
        end

        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
                        
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3); %create presentation of specified duration
            preFrames = round(obj.frameRate * (obj.preTime/1e3));
            
            % create shapes
            % checkerboard is filled from top left (is 1,1)
            checkerboard = stage.builtin.stimuli.Image(uint8(zeros(obj.resolution, obj.resolution)));
            checkerboard.position = canvasSize / 2;
            checkerboard.size = obj.um2pix([obj.spotSize, obj.spotSize]);
            checkerboard.setMinFunction(GL.NEAREST);
            checkerboard.setMagFunction(GL.NEAREST);
            p.addStimulus(checkerboard);
            
            % add controllers
            % dimensions are swapped correctly
            checkerboardImageController = stage.builtin.controllers.PropertyController(checkerboard, 'imageMatrix',...
                @(state)getImageMatrix(obj, state.frame - preFrames));
            p.addController(checkerboardImageController);
            
%             obj.setOnDuringStimController(p, checkerboard);
            
            % TODO: verify X vs Y in matrix
            
            function i = getImageMatrix(obj, frame)
                intensity = abs(obj.grating)*obj.contrastMean;
                if frame >= 0
                    intensity = intensity + obj.grating * obj.waveVec(frame+1);
                end
                intensity = intensity + obj.surround * obj.meanLevel;
                i = uint8(255 * intensity);
            end
            

        end
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
    end
    
end
