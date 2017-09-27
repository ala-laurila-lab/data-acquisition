classdef Notepad < symphonyui.ui.Module
    
    properties (Access = private)
        textArea
        jEditbox
        jScrollPanel
        addComments
        log
        settings
    end
    
    methods
        
        function obj = Notepad()
            obj.settings = ala_laurila_lab.modules.settings.NotepadSettings();
            obj.log = log4m.LogManager.getLogger(class(obj));
        end
        
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
            obj.addComments =  uimenu(figureHandle, ...
                'Label', 'Add Comments',...
                'Callback', @(h,d) obj.onSelectAddComments());
            try
                obj.jScrollPanel.setVerticalScrollBarPolicy(obj.jScrollPanel.java.VERTICAL_SCROLLBAR_AS_NEEDED);
                viewPort = obj.jScrollPanel.getViewport();
                obj.jEditbox = handle(viewPort.getView, 'CallbackProperties');
                obj.jEditbox.setEditable(false);
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
        
        function willGo(obj)
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load settings: ' x.message], x);
            end
        end
        
        function willStop(obj)
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save settings: ' x.message], x);
            end
        end        
    end
    
    methods (Access = private)
        
        function initLogger(obj)
            options = symphonyui.app.Options.getDefault();
            logFile = [options.fileDefaultLocation filesep options.fileDefaultName() '.log'];
            
            daqLogger = sa_labs.factory.getInstance('daqUILogger');
            daqLogger.setFilename(logFile);
            obj.jEditbox.setEditable(true);
            
            fid = fopen(logFile, 'rt');
            text = textscan(fid,'%s','Delimiter','\n');
            fclose(fid);
            cellfun(@(msg) obj.appendText(sprintf('%s \n', msg)), text{:});
            sa_labs.common.DaqLogger.setLogging(logging.logging.OFF);
        end
        
        function onServiceChangedControllerState(obj, ~,  ~)
            obj.setLogging();
        end
        
        function onSelectAddComments(obj, ~, ~)
            ala_laurila_lab.modules.CommentsPresenter().go();
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
        end
        
        function setCaretPosition(obj)
            javaTextArea = obj.jScrollPanel.getComponent(0).getComponent(0);
            javaTextArea.getCaret().setUpdatePolicy(2);
        end
        
        function loadSettings(obj)
            if ~isempty(obj.settings.viewPosition)
                p1 = obj.view.position;
                p2 = obj.settings.viewPosition;
                obj.view.position = [p2(1) p2(2) p1(3) p1(4)];
            end
        end
        
        function saveSettings(obj)
            obj.settings.viewPosition = obj.view.position;
            obj.settings.save();
        end
    end
end

