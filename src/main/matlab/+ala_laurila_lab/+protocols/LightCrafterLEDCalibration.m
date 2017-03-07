classdef LightCrafterLEDCalibration < sa_labs.protocols.StageProtocol
    
    properties
        
        preTime = 500           % Spot leading duration (ms)
        stimTime = 1000         % Spot duration (ms)
        tailTime = 1000         % Spot trailing duration (ms)
        spotIntensity = 1       % spot intensity 
        spotSize = 500;         % Spot size in (um)
        numberOfCycles = 1;     % number of repeats
        user = 'Anna'
    end
    
    
    properties (Hidden, Dependent)
        totalNumEpochs
        cycleNumber
    end

    properties (Hidden, Transient)
        ledCurrentSteps
        linearityMeasurements
        rigProperty
    end
    
    properties (Hidden)
        userType = symphonyui.core.PropertyType('char', 'row', {'Anna', 'Petri', 'Sathish', 'Sami'})
        responsePlotMode = false
    end
    
    methods
        
        function prepareRun(obj)
            % obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice('Optometer'));
            
            % set LED current vector
            obj.ledCurrentSteps = [0:1:15 20:10:100 120:20:240 255];
            calibrationProtocol = [class(obj) '-blueLed_' num2str(obj.stimTime)];
            
            import ala_laurila_lab.entity.*;

            obj.linearityMeasurements = LightCrafterLinearityMeasurement.empty(0, obj.numberOfCycles);

            for i = 1 : obj.numberOfCycles
                linearity = LightCrafterLinearityMeasurement(calibrationProtocol);
                linearity.calibrationDate = datestr(date, 'dd/mm/yyyy');
                obj.linearityMeasurements(i) = linearity;
            end
            obj.rigProperty = ala_laurila_lab.factory.getInstance('rigProperty');
            prepareRun@sa_labs.protocols.StageProtocol(obj);
        end

        function prepareEpoch(obj, epoch)

            index = mod(obj.numEpochsPrepared, length(obj.blueLEDs)) + 1;           
            ledCurrent = obj.ledCurrentSteps(index);
            
            lightCrafter = obj.rig.getDevice('LightCrafter');
            lightCrafter.setLedCurrents(0, 0, ledCurrent, 0);

            % let the projector get set up
            pause(0.2); 

            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            optometer = obj.rig.getDevice('Optometer');
            epoch.addResponse(optometer);
            epoch.addParameter('ledCurrent', ledCurrent);

            obj.linearityMeasurements(obj.cycleNumber).ledCurrent = ledCurrent;
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
            optometer = obj.rig.getDevice('Optometer');
            quantities = epoch.getResponse(optometer).getData();
            toIndex = @(t) (t * obj.samplingRate / 1e3);
            start = toIndex(obj.preTime);
            flux = quantities(start : start + toIndex(obj.tailTime));
            
            obj.linearityMeasurements(obj.cycleNumber).flux = flux;
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
        end

        function completeRun(obj)
            service = obj.rigProperty.rigDescription.getCalibrationService();
            service.addLinearityMeasurement(obj.linearityMeasurements, obj.user);
            
            completeRun@sa_labs.protocols.StageProtocol(obj, epoch);           
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * length(obj.ledCurrentSteps);
        end

        function n = get.cycleNumber(obj)
            n = (obj.totalNumEpochs / length(obj.ledCurrentSteps)) + 1;
        end
        
        function [rstar, mstar, sstar] = convertIntensityToIsomerizations(obj, intensity)
            rstar = [];
            mstar = [];
            sstar = [];
        end
    end
end