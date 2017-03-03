classdef LightCrafterLEDCalibration < sa_labs.protocols.StageProtocol

    properties
        
        preTime = 500           % Spot leading duration (ms)
        stimTime = 1000         % Spot duration (ms)
        tailTime = 1000         % Spot trailing duration (ms)
        intensity = 1           % spot intensity 
        spotSize = 500;         % Spot size in (um)
        numberOfCycles  = 1;    % number of repeats
        led
        user
    end
    
    
    properties (Hidden, Dependent)
        totalNumEpochs
        cycleNumber
    end

    properties (Hidden, Transient)
        ledCurrentSteps
        ledType = symphonyui.core.PropertyType('char', 'row', {'red', 'blue', 'green'})
        userType = symphonyui.core.PropertyType('char', 'row', {'Sathish', 'Anna', 'Petri'})
        linearityMeasurements
    end
    
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice('Optometer'));
            
            % set LED current vector
            obj.ledCurrentSteps = [0:1:15 20:10:100 120:20:240 255];
            calibrationProtocol = [class(obj) '-' obj.led '_' num2str(obj.stimTime)];
            
            obj.linearityMeasurements = ala_laurila_lab.LinearityMeasurement.empty(0, numberOfCycles);

            for i = 1 : obj.numberOfCycles
                linearity = ala_laurila_lab.LinearityMeasurement(calibrationProtocol);
                linearity.voltageExponent = 1;
                linearity.calibrationDate = now;
                obj.linearityMeasurements(i) = linearity;
            end
        end

        function prepareEpoch(obj, epoch)

            redLed = 0;
            blueLed = 0;
            greenLed = 0;
            index = mod(obj.numEpochsPrepared, length(obj.blueLEDs)) + 1;           
            
            switch (obj.led)
                case 'blue'
                    blueLed = obj.ledCurrentSteps(index);
                case 'red'
                    redLed = obj.ledCurrentSteps(index);
                case 'green'
                    greenLed = obj.ledCurrentSteps(index);
            end

            lightCrafter = obj.rig.getDevice('LightCrafter');
            lightCrafter.setLedCurrents(redLed, greenLed, blueLed);

            % let the projector get set up
            pause(0.2); 

            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            optometer = obj.rig.getDevice('Optometer');
            epoch.addResponse(optometer);
            epoch.addParameter('ledCurrent', obj.ledCurrentSteps(index));

            obj.linearityMeasurements(obj.cycleNumber).addVoltage(obj.ledCurrentSteps(index));
        end

        function p = createPresentation(obj)
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);

            %set background 
            p.setBackgroundColor(obj.meanLevel);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));
            spot.radiusY = spot.radiusX;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            function c = onDuringStim(state, preTime, stimTime, intensity, meanLevel)
                c = meanLevel;
                if state.time > preTime* 1e-3 && state.time < = (preTime + stimTime) * 1e-3
                    c = intensity;
                end
            end

            controller = stage.builtin.controllers.PropertyController(spot, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            p.addController(controller);
        end

        function completeEpoch(obj, epoch)
            optometer = obj.rig.getDevice('Optometer');
            quantities = epoch.getResponse(optometer).getData();
            toIndex = @(t) (t * obj.samplingRate / 1e3);
            start = toIndex(preTime);
            flux = quantities(start : start + toIndex(tailTime));
            
            obj.linearityMeasurements(obj.cycleNumber).addCharge(flux);
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
        end

        function completeRun(obj)
            service = ala_laurila_lab.AaltoPatchRigCailbration.getCalibrationService();
            service.addLinearityMeasurement(obj.linearityMeasurements, obj.user);
            
            completeRun@sa_labs.protocols.StageProtocol(obj, epoch);           
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * length(obj.ledCurrentSteps);
        end

        function n = get.cycleNumber(obj)
            n = (obj.totalNumEpochs / length(obj.ledCurrentSteps)) + 1;
        end
    end
end