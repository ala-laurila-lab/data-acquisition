classdef MockedLightCrafterDevice <  symphonyui.core.Device % sa_labs.devices.LightCrafterDevice 
    properties (Access = private)
        auto = false
        red = false
        green = false
        blue = true
        uv = false
        current = 1;
        
    end
    
    properties
        stageClient
        lightCrafter % TODO: this needs to be mocked
    end
    
    methods
        
        function obj = MockedLightCrafterDevice(varargin)
%             obj = obj@sa_labs.devices.LightCrafterDevice(varargin{:});
            ip = inputParser();
            ip.addParameter('host', 'localhost', @ischar);
            ip.addParameter('port', 5678, @isnumeric);
            ip.addParameter('micronsPerPixel', @isnumeric);
            ip.parse(varargin{:});
            
            cobj = Symphony.Core.UnitConvertingExternalDevice(['LightCrafter Stage@' ip.Results.host], 'Texas Instruments', Symphony.Core.Measurement(0, symphonyui.core.Measurement.UNITLESS));
            obj@symphonyui.core.Device(cobj);
            obj.cobj.MeasurementConversionTarget = symphonyui.core.Measurement.UNITLESS;
            
            obj.stageClient = stage.core.network.StageClient();
            obj.stageClient.connect(ip.Results.host, ip.Results.port);
            obj.stageClient.setMonitorGamma(1);
            
            trueCanvasSize = obj.stageClient.getCanvasSize();
            canvasSize = [trueCanvasSize(1) * 2, trueCanvasSize(2)];
            frameTrackerSize = [80,80];
            frameTrackerPosition = [40,40];
            
            obj.stageClient.setCanvasProjectionIdentity();
            obj.stageClient.setCanvasProjectionOrthographic(0, canvasSize(1), 0, canvasSize(2));
            
            obj.lightCrafter = [];
            
%             obj.lightCrafter = LightCrafter4500(obj.stageClient.getMonitorRefreshRate());
%             obj.lightCrafter.connect();
%             obj.lightCrafter.setMode('pattern');
%             [auto, red, green, blue] = obj.lightCrafter.getLedEnables();
            [auto, red, green, blue] = getLedEnables(obj);
            monitorRefreshRate = obj.stageClient.getMonitorRefreshRate();
            renderer = stage.builtin.renderers.PatternRenderer(1, 8);
            obj.stageClient.setCanvasRenderer(renderer);
            
            obj.addConfigurationSetting('canvasSize', canvasSize, 'isReadOnly', true);
            obj.addConfigurationSetting('trueCanvasSize', trueCanvasSize, 'isReadOnly', true);
            obj.addConfigurationSetting('frameTrackerSize', frameTrackerSize);
            obj.addConfigurationSetting('frameTrackerPosition', frameTrackerPosition);
            obj.addConfigurationSetting('monitorRefreshRate', monitorRefreshRate, 'isReadOnly', true);
            obj.addConfigurationSetting('prerender', false, 'isReadOnly', true);
            obj.addConfigurationSetting('lightCrafterLedEnables',  [auto, red, green, blue], 'isReadOnly', true);
            obj.addConfigurationSetting('lightCrafterPatternRate', 120, 'isReadOnly', true); %TODO: mock the pattern rate?
            obj.addConfigurationSetting('micronsPerPixel', ip.Results.micronsPerPixel, 'isReadOnly', true);
            obj.addConfigurationSetting('canvasTranslation', [0,0]);
        end
        
        function setLightCrafter(obj, ~, ~)
            obj.lightCrafter = [];
        end
        
        function setLedEnables(obj, auto, red, green, blue, uv)
            obj.auto = auto;
            obj.red = red;
            obj.green = green;
            obj.blue = blue;
            obj.uv = uv;
        end
        
        function setLedCurrents(obj, varargin)
            obj.current = 1;
        end
        
        function [auto, red, green, blue] = getLedEnables(obj)
            auto = obj.auto;
            red = obj.red;
            green = obj.green;
            blue = obj.blue;
        end
        
        function setPatternAttributes(obj, varargin)
           renderer = stage.builtin.renderers.PatternRenderer(1, 8);
           obj.stageClient.setCanvasRenderer(renderer);
        end
        
        function [bitDepth, color, numPatterns] = getPatternAttributes(~)
            bitDepth = 8;
            color = 1;
            numPatterns = 1;
        end
        
        function r = getPatternRate(~)
            r = 1 * 60;
        end
        
        function play(obj, presentation)
            canvasSize = obj.getCanvasSize();
            canvasTranslation = obj.getConfigurationSetting('canvasTranslation');
            obj.stageClient.setCanvasProjectionIdentity();
            obj.stageClient.setCanvasProjectionOrthographic(0, canvasSize(1), 0, canvasSize(2));
            obj.stageClient.setCanvasProjectionTranslate(canvasTranslation(1), canvasTranslation(2), 0);
            
            background = obj.getBackground();
            backgroundIntensity = obj.getConfigurationSetting('backgroundIntensity');
            background.color = backgroundIntensity;
            backgroundPattern = obj.getConfigurationSetting('backgroundPattern');
            background.color = backgroundIntensity;
            
            if obj.getConfigurationSetting('numberOfPatterns') > 1
                backgroundPatternController = stage.builtin.controllers.PropertyController(background, 'opacity',...
                    @(state)(1 * (state.pattern == backgroundPattern - 1)));
                presentation.addController(backgroundPatternController);
            end
            presentation.insertStimulus(1, background);
            
            % FRAME TRACKER
            tracker = stage.builtin.stimuli.Rectangle();
            tracker.size = obj.getFrameTrackerSize();
            tracker.position = obj.getFrameTrackerPosition() - canvasTranslation;
            presentation.addStimulus(tracker);
            % appears on all patterns
            duration = obj.getFrameTrackerDuration();
            trackerColor = stage.builtin.controllers.PropertyController(tracker, 'color', ...
                @(s)mod(s.frame, 2) && double(s.time + (1/s.frameRate) < duration));
            presentation.addController(trackerColor);
            
            % RENDER
            if obj.getPrerender()
                player = stage.builtin.players.PrerenderedPlayer(presentation);
            else
                player = stage.builtin.players.RealtimePlayer(presentation);
            end
            player.setCompositor(stage.builtin.compositors.PatternCompositor());
            obj.stageClient.play(player);
        end
        
    end
end

