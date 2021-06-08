classdef ProjectorNonLinearityCalibration < sa_labs.protocols.StageProtocol
    
    properties
        
        preTime = 500           % Spot leading duration (ms)
        stimTime = 1000         % Spot duration (ms)
        tailTime = 1000         % Spot trailing duration (ms)
        spotIntensity = 1       % spot intensity 
        spotSize = 500;         % Spot size in (um)
        numberOfCycles = 1;     % number of repeats
        user = 'Natali'
        maxLed = 255
        ledStartAfter = 9
    end
    
    
    properties (Hidden, Dependent)
        totalNumEpochs
        cycleNumber
        numSteps
    end

    properties (Hidden, Transient)        
        currentStep = 0 
        optometer
    end
    
    properties (Hidden)
        outputs
        measurements
        userType = symphonyui.core.PropertyType('char', 'row', {'Aarni', 'Petri', 'Natali', 'Johan'})
        responsePlotMode = false
    end
    
    methods
        
        function prepareRun(obj)
           obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice('Optometer'));
           handler = obj.showFigure('symphonyui.builtin.figures.CustomFigure', @obj.updateGammaTable); 

              % Create gamma table figure
              if ~isfield(handler.userData, 'axesHandle')
                h = handler.getFigureHandle();
                t = 'Optometer Power Measurement vs. Intensity';
                set(h, 'Name', t);
                a = axes(h, ...
                    'FontUnits', get(h, 'DefaultUicontrolFontUnits'), ...
                    'FontName', get(h, 'DefaultUicontrolFontName'), ...
                    'FontSize', get(h, 'DefaultUicontrolFontSize'));
                title(a, t);
                xlabel(a, 'Output (inten.)');
                ylabel(a, 'Voltage (mv)');
                set(a, 'Box', 'off', 'TickDir', 'out');
                handler.userData.axesHandle = a;
                handler.userData.gammaLineHandle = line(0, 0, 'Parent', a);
            end
            
           prepareRun@sa_labs.protocols.StageProtocol(obj);
            % Create output intensities that grow from led start to maxLed
            obj.currentStep = 1;

            obj.outputs = obj.ledStartAfter + obj.currentStep : 1: obj.maxLed;
            obj.measurements = zeros(1, obj.numSteps);
            obj.optometer = ala_laurila_lab.devices.OptometerUDTS470();
        end

        function updateGammaTable(obj, handler, epoch)
            response = epoch.getResponse(obj.rig.getDevice('Optometer'));
            quantities = response.getData();
            quantities = quantities * 1e3; % V to mV

            prePts = round(obj.preTime / 1e3 * obj.sampleRate);
            stimPts = round(obj.stimTime / 1e3 * obj.sampleRate);
            
            measurementStart = prePts + (stimPts / 2);
            measurementEnd = prePts + stimPts;

            baseline = mean(quantities(1:prePts));            
            measurement = mean(quantities(measurementStart:measurementEnd))
            measurement = mean(quantities(quantities > 0.7 * measurement))
            obj.measurements(obj.currentStep) = measurement - baseline;
            
            set(handler.userData.gammaLineHandle, 'Xdata', obj.outputs(1:obj.currentStep), 'Ydata', obj.measurements(1:obj.currentStep));

            axesHandle = handler.userData.axesHandle;
            %xlim(axesHandle, [min(obj.outputs(1:obj.currentStep)) - 0.05, max(obj.outputs(1:obj.currentStep)) + 0.05]);
            ylim(axesHandle, [min(obj.measurements) - 0.05, max(obj.measurements) + 0.05]);

            obj.currentStep = obj.currentStep + 1;
        end

        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            ledCurrent = obj.currentStep + obj.ledStartAfter;           
            lightCrafter = obj.rig.getDevice('LightCrafter');
            lightCrafter.setLedCurrents(0, 0, ledCurrent, 0);

            % let the projector get set up
            pause(0.2); 
            epoch.addResponse(obj.rig.getDevice('Optometer'));
            epoch.addParameter('ledCurrent', ledCurrent);
            
        end

        function p = createPresentation(obj)
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            p.setBackgroundColor(obj.meanLevel);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));
            spot.radiusY = spot.radiusX;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            function c = setColor(state, preTime, stimTime, meanLevel, intensity)
                c = meanLevel;
                if state.time >= preTime * 1e-3 && state.time <= (preTime + stimTime) * 1e-3
                    c = intensity;
                end
            end

            colorController = stage.builtin.controllers.PropertyController(spot, 'color', ...
                @(s) setColor(s, obj.preTime, obj.stimTime, obj.meanLevel, obj.spotIntensity));
            
            spotVisible = stage.builtin.controllers.PropertyController(spot, 'visible', ...
                @(state) state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            
            if obj.meanLevel > 0
                p.addController(colorController);
            else
                p.addController(spotVisible);
            end
        end

        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            if obj.currentStep > obj.numSteps
                % Normalize measurements with span from 0 to 1.
                mrange = max(obj.measurements) - min(obj.measurements);
                baseline = min(obj.measurements);

                outs = obj.outputs;
                values = (obj.measurements - baseline) / mrange;

                % Create ideal linear gamma vector.
                linear = linspace(0, 1, obj.numSteps); 

                h = figure('Name', 'Gamma', 'NumberTitle', 'off');
                a = axes(h);
                plot(a, outs, values, '.', outs, linear, '-');
                legend(a, 'Measurements', 'Ideal');
                title(a, 'Gamma');
                set(a, ...
                    'FontUnits', get(h, 'DefaultUicontrolFontUnits'), ...
                    'FontName', get(h, 'DefaultUicontrolFontName'), ...
                    'FontSize', get(h, 'DefaultUicontrolFontSize'));
            
            linearity = struct();
            linearity.ledCurrent = outs;
            linearity.measurements = obj.measurements;
            linearity.normalizedMeasurements = values;
            linearity.spotSize = obj.spotSize;
            linearity.spotIntensity = obj.spotIntensity;
            linearity.user = obj.user;
            linearity.date = char(datetime);
            linearity.preTime = obj.preTime;
            linearity.stimTime = obj.stimTime;
            linearity.tailTime = obj.tailTime;
             
            % Save the results to json file            
            name = [matlab.lang.makeValidName(char(datetime)), '-non-linearity.json'];
            location = [fileparts(which('aalto_rig_calibration_data_readme')) filesep 'projector_led_nonlinearity'];
            savejson('', linearity, [location filesep name]);
            end            
        end

        function completeRun(obj)
            completeRun@sa_labs.protocols.StageProtocol(obj);
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * obj.numSteps;
        end

        function n = get.cycleNumber(obj)
            n = floor(obj.numEpochsCompleted /  obj.numSteps) + 1;
        end
        
        function n = get.numSteps(obj)
            n = obj.maxLed - obj.ledStartAfter;
        end

    end
end