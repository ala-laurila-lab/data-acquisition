classdef Notepad < symphonyui.ui.Module
    
    events
        NewFile
        OpenFile
        CloseFile
        Exit
    end
    
    properties (Access = private)
        fileMenu
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
                'Callback', @(h,d) notify(obj, 'NewFile'));
            obj.fileMenu.openFile = uimenu(obj.fileMenu.root, ...
                'Label', 'Open...', ...
                'Callback', @(h,d) notify(obj, 'OpenFile'));
            obj.fileMenu.closeFile = uimenu(obj.fileMenu.root, ...
                'Label', 'Close', ...
                'Callback', @(h,d) notify(obj, 'CloseFile'));
            obj.fileMenu.exit = uimenu(obj.fileMenu.root, ...
                'Label', 'Exit', ...
                'Separator', 'on', ...
                'Callback', @(h,d) notify(obj, 'Exit'));
            
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
            
            d = obj.documentationService;
            %obj.addListener(d, 'AddedSource', @obj.onServiceAddedSource);
            %obj.addListener(d, 'BeganEpochGroup', @obj.onServiceBeganEpochGroup);
            
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
            daqLogger.setLogLevel(logging.logging.INFO);
            
            daqLogger = sa_labs.factory.getInstance('daqLogger');
            daqLogger.setLogLevel(logging.logging.INFO);
            
            fid = fopen(logFile, 'rt');
            text = textscan(fid,'%s','Delimiter','\n');
            fclose(fid);
            text = sprintf('%s' , evalc('disp(text{:})'));
           obj.appendText(text);
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

