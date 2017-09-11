classdef MockedLightCrafterDevice < sa_labs.devices.LightCrafterDevice
    
    properties (Access = private)
        auto = false
        red = false
        green = false
        blue = true
        uv = false
        current = 1;
    end
    
    methods
        
        function obj = MockedLightCrafterDevice(varargin)
            obj = obj@sa_labs.devices.LightCrafterDevice(varargin{:});
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

