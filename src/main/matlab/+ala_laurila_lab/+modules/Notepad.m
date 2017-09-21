classdef Notepad < symphonyui.ui.Module
    
    properties (Access = private)
        textArea
        jEditbox
        jScrollPanel
    end
    
    methods
        
        function createUi(obj, figureHandle)
            
            set(figureHandle, ...
                'Name', 'Notepad', ...
                'Position', appbox.screenCenter(240, 340));
            
            mainLayout = uix.VBox( ...
                'Parent', figureHandle, ...
                'Padding', 9, ...
                'Spacing', 1);
            
            obj.textArea = uicontrol(...
                'Parent', mainLayout,...
                'Style','Edit',...
                'HorizontalAlignment','left',...
                'FontName', 'Consolas',...
                'FontSize', 12,...
                'Max',1000);
            
            obj.jScrollPanel = findjobj(obj.textArea);
            try
                obj.jScrollPanel.setVerticalScrollBarPolicy(obj.jScrollPanel.java.VERTICAL_SCROLLBAR_AS_NEEDED);
                viewPort = obj.jScrollPanel.getViewport();
                obj.jEditbox = handle(viewPort.getView, 'CallbackProperties');
                obj.jEditbox.setEditable(true);
            catch exception
                disp(exception.getReport);
            end
            obj.initLogger();
        end
    end
    
    methods (Access = protected)
        function bind(obj)
            bind@symphonyui.ui.Module(obj);
            
            a = obj.acquisitionService;
            obj.addListener(a, 'ChangedControllerState', @obj.onServiceChangedControllerState);
            daqLogger = sa_labs.factory.getInstance('daqUILogger');
            obj.addListener(daqLogger, 'MessageLogged', @obj.onDaqLoggerMessageLogged);
            
            d = obj.documentationService;
            obj.addListener(d, 'AddedSource', @obj.onServiceAddedSource);
            obj.addListener(d, 'CreatedFile', @obj.onServiceCreatedOrOpenedFile);
            obj.addListener(d, 'OpenedFile', @obj.onServiceCreatedOrOpenedFile);
            
            if obj.documentationService.hasOpenFile()
                experiment = obj.documentationService.getExperiment();
                obj.addListener(experiment, 'AddedNote', @obj.onServiceAddedNote);
            end
        end
        
        function bindAddedNoteListener(obj, source)
            obj.addListener(source, 'AddedNote', @obj.onServiceAddedNote);
        end
    end
    
    methods (Access = private)
        
        function initLogger(obj)
            options = symphonyui.app.Options.getDefault();
            logFile = [options.fileDefaultLocation filesep options.fileDefaultName() '.log'];
            
            daqLogger = sa_labs.factory.getInstance('daqUILogger');
            daqLogger.setFilename(logFile);
            
            fid = fopen(logFile, 'rt');
            text = textscan(fid,'%s','Delimiter','\n');
            fclose(fid);
            cellfun(@(msg) obj.appendText(sprintf('%s \n', msg)), text{:});
            sa_labs.common.DaqLogger.setLogging(logging.logging.OFF);
        end
        
        function onServiceChangedControllerState(obj, ~,  ~)
            obj.setLogging();
        end
        
        function setLogging(obj)
            import symphonyui.core.ControllerState;
            import sa_labs.common.DaqLogger;
            if obj.acquisitionService.getControllerState() == ControllerState.RECORDING
                DaqLogger.setLogging(logging.logging.INFO);
            else
                DaqLogger.setLogging(logging.logging.OFF);
            end
        end
        
        function onServiceAddedSource(obj, ~, eventData)
            obj.bindAddedNoteListener(eventData.data);
        end
        
        function onServiceCreatedOrOpenedFile(obj, ~, ~)
            experiment = obj.documentationService.getExperiment();
            obj.bindAddedNoteListener(experiment);
        end
        
        function onServiceAddedNote(obj, ~, eventData)
            import sa_labs.common.DaqLogger;
            comments = eventData.data.text;
            DaqLogger.setLogging(logging.logging.INFO);
                    
            %delimitter = @(msg) strcat(repmat('*', 1, 25), msg , repmat('*', 1, 25));
            %comments = sprintf('\n%s \n%s \n%s', delimitter(' Start Comments '), notes.text, delimitter(' End Comments '));
            DaqLogger.log([' Notes: ' comments]);
            obj.setLogging()
        end
        
        function appendText(obj, text)
            obj.jEditbox.setCaretPosition(obj.jEditbox.getDocument().getLength());
            obj.jEditbox.replaceSelection(text); 
            
        end
        
        function onDaqLoggerMessageLogged(obj, ~, eventData)
            obj.appendText(eventData.data);
            obj.setCaretPosition();
        end
        
        function setCaretPosition(obj)
            javaTextArea = obj.jScrollPanel.getComponent(0).getComponent(0);
            javaTextArea.getCaret().setUpdatePolicy(2);
        end
    end
end

