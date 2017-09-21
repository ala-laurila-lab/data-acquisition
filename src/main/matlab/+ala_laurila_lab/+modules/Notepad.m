classdef Notepad < symphonyui.ui.Module
    
    properties (Access = private)
        fileMenu
        addComments
        textArea
        jEditbox
        jScrollPanel
    end
    
    methods
        
        function createUi(obj, figureHandle)
            
            set(figureHandle, ...
                'Name', 'Notepad', ...
                'Position', appbox.screenCenter(240, 340));
            
            obj.fileMenu.root = uimenu(figureHandle, ...
                'Label', 'File');
            obj.fileMenu.newFile = uimenu(obj.fileMenu.root, ...
                'Label', 'New...', ...
                'Callback', @(h,d) obj.onSelectNewFile());
            obj.fileMenu.openFile = uimenu(obj.fileMenu.root, ...
                'Label', 'Open...', ...
                'Callback', @(h,d) obj.onSelectOpenFile());
            obj.fileMenu.closeFile = uimenu(obj.fileMenu.root, ...
                'Label', 'Close', ...
                'Callback', @(h,d) obj.onSelectCloseFile());
            obj.fileMenu.exit = uimenu(obj.fileMenu.root, ...
                'Label', 'Exit', ...
                'Separator', 'on', ...
                'Callback', @(h,d) obj.onSelectExit());
            
            obj.addComments =  uimenu(figureHandle, ...
                'Label', 'Add Comments',...
                'Callback', @(h,d) obj.onSelectAddComments());
            
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
            import symphonyui.core.ControllerState;
            import sa_labs.common.DaqLogger;
            if obj.acquisitionService.getControllerState() == ControllerState.RECORDING
                DaqLogger.setLogging(logging.logging.INFO);
            else
                DaqLogger.setLogging(logging.logging.OFF);
            end
        end
        
        function onSelectAddComments(obj, ~, ~)
             ala_laurila_lab.modules.CommentsPresenter().go();
             obj.onServiceChangedControllerState();
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
    end
end

