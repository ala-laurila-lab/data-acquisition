classdef RunWithMetadata < symphonyui.ui.Module
    properties (Access=private)
        axes
        protocol
        numEpochsCompleted
        shouldContinuePreparingEpochs
        dir
    end
    properties (Dependent)
       sampleRate
    end
    
    methods
         function createUi(obj, figureHandle)
            import appbox.*;
            
            set(figureHandle, ...
                'Name', 'Run With Metadata', ...
                'Position', screenCenter(550, 250));
            mainLayout = uix.VBox( ...
                'Parent', figureHandle, ...
                'Padding', 11, ...
                'Spacing', 11);
            
           obj.axes = axes('Parent', mainLayout);
           buttonLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Padding', 11, ...
                'Spacing', 11);
           uicontrol( ...
            'Parent', buttonLayout, ...
            'Style', 'pushbutton', ...
            'String', 'Record', ...
            'Callback',  @obj.onRecord);
           uicontrol( ...
            'Parent', buttonLayout, ...
            'Style', 'pushbutton', ...
            'String', 'Stop', ...
            'Callback',  @obj.onStop);
        
            menu = Menu(figureHandle);
            menu.addPushTool('label','Set directory','callback',@obj.setDirectory);
            
            obj.dir = pwd;
         end
         
         function setDirectory(obj, ~, ~)
            obj.dir = uigetdir;
         end
         
         function onStop(obj, ~, ~)
             obj.shouldContinuePreparingEpochs = false;
         end
         
         function onRecord(obj, ~, ~)
             obj.protocol = feval(obj.acquisitionService.getSelectedProtocol());
             d = obj.acquisitionService.getProtocolPropertyDescriptors();
             for i = d
                 if i.isReadOnly
                     continue
                 end
                 obj.protocol.(i.name) = i.value;
             end
             
             eg = obj.documentationService.getCurrentEpochGroup();
             stage = obj.configurationService.getDevice('Stage');
             
             obj.protocol.setRig(obj);
             obj.protocol.prepareRun();
             tic;
             e = [];
             tt = [];
             obj.numEpochsCompleted = 0;
             obj.shouldContinuePreparingEpochs = true;
             while obj.protocol.shouldContinuePreparingEpochs && obj.shouldContinuePreparingEpochs
                 last_e = e;
                 e = symphonyui.core.Epoch('test-epoch');
                 obj.protocol.prepareEpoch(e);

                 pr = obj.protocol.createPresentation();
                 
                 if ~isempty(last_e)
                    i = stage.getPlayInfo(); %blocking call, flipDurations from last presentation                                 
                    obj.numEpochsCompleted = obj.numEpochsCompleted + 1;
                    obj.updateUI(i.flipDurations);
                end
                
                 t = toc;
                 
                 if ~isempty(last_e)
                     obj.protocol.completeEpoch(last_e); %only works if no amp selected?
                 end
                 
                 last_tt = tt;
                 tt = datestr(datetime,'yyyymmdd_HHMMSS');
                 tic;
                 stage.play(pr);
                 
                 if ~isempty(last_e)
                     % plot/save i.flipDurations;
                     output = struct('epochParameters',last_e.parameters,'protocolParameters',obj.protocol.getPropertyMap(), 'epochStartTime', last_tt, 'frameDuration', i.flipDurations, 'blockingTime', t);  %#ok<*NASGU>
                     save(sprintf('%s%s%s_epoch.mat',obj.dir,filesep,last_tt) ,'-struct','output');
                 end
             end
             
             i = stage.getPlayInfo(); %blocking call, flipDurations from last presentation                                 
             obj.numEpochsCompleted = obj.numEpochsCompleted + 1;
             obj.updateUI(i.flipDurations);
             t = toc;

             obj.protocol.completeEpoch(last_e); %only works if no amp selected?
             output = struct('epochParameters',e.parameters,'protocolParameters',obj.protocol.getPropertyMap(), 'epochStartTime', tt, 'frameDuration', i.flipDurations, 'blockingTime', t); 
             save(sprintf('%s%s%s_epoch.mat',obj.dir,filesep,tt) ,'-struct','output');

             obj.protocol.completeRun();
         end
         
         function device = getDevice(obj, name)
            device = obj.configurationService.getDevice(name);
         end
         
         function devices = getDevices(obj, namestr)
             devices = obj.configurationService.getDevices(namestr);
         end
         
         function names = getDeviceNames(obj, namestr)
            names = cellfun(@(x) x.name, obj.getDevices(namestr), 'uni', 0);
         end
         
         function rate = get.sampleRate(obj) 
             rate = obj.getDevice('Amp1').sampleRate; % a dummy value, should be fine?
         end
         
         function set.sampleRate(obj, rate)
             %nop
         end
         
         function rateType = sampleRateType(obj)
            rateType = symphonyui.core.PropertyType('denserealdouble','scalar',{obj.sampleRate.quantity});
         end
         
         function updateUI(obj, frame_durations)
            plot(obj.axes, frame_durations);
            xlabel(obj.axes, 'Frame #');
            ylabel(obj.axes, 'Frame duration');
            title(obj.axes, sprintf('Trial %d of %d',obj.numEpochsCompleted, obj.protocol.totalNumEpochs));
            drawnow;
         end
    end
    
end

