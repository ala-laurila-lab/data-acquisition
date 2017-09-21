classdef CommentsPresenter < appbox.Presenter
    
    properties (Access = private)
        textArea
        commentsView
    end
    
    methods
        
        function obj = CommentsPresenter()
            view = symphonyui.ui.views.FigureView();
            obj = obj@appbox.Presenter(view);
            try
                obj.createUi(view.getFigureHandle());
            catch x
                delete(view);
                rethrow(x);
            end
            obj.commentsView = view;
        end
        
        function createUi(obj, figureHandle)
            
            import appbox.*;
            
            set(figureHandle, ...
                'Name', 'Add Note', ...
                'Position', screenCenter(450, 200), ...
                'Resize', 'off');
            
            mainLayout = uix.VBox( ...
                'Parent', figureHandle, ...
                'Padding', 11, ...
                'Spacing', 11);
            
            noteLayout = uix.VBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
            obj.textArea = TextArea( ...
                'Parent', noteLayout, ...
                'Scrollable', 'true');
            
            set(noteLayout, 'Heights', 250);
            
            % Add/Cancel controls.
            controlsLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
            uix.Empty('Parent', controlsLayout);
            uicontrol( ...
                'Parent', controlsLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Add', ...
                'Interruptible', 'off', ...
                'Callback',  @obj.onViewSelectedAdd);
            uicontrol( ...
                'Parent', controlsLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Cancel', ...
                'Interruptible', 'off', ...
                'Callback', @obj.onViewSelectedCancel);
            set(controlsLayout, 'Widths', [-1 75 75]);
            
            set(mainLayout, 'Heights', [-1 23]);
            
            % Set add button to appear as the default button.
            try %#ok<TRYNC>
                h = handle(obj.figureHandle);
                h.setDefaultButton(obj.addButton);
            end
            
        end
    end
    
    methods (Access = protected)
        
        function didGo(obj)
          obj.textArea.String = strcat(repmat('*', 1, 25), ' Start comments ', repmat('*', 1, 25));
          obj.textArea.Editable = true;
        end
        
        function bind(obj)
            bind@appbox.Presenter(obj);
            obj.addListener(obj.commentsView, 'KeyPress', @obj.onViewKeyPress);
        end
    end
    
    methods (Access = private)
        
        function onViewKeyPress(obj, ~, event)
            switch event.data.Key
                case 'return'
                    obj.onViewSelectedAdd();
                case 'escape'
                    obj.onViewSelectedCancel();
            end
        end
        
        function onViewSelectedAdd(obj, ~, ~)
            
            text = obj.textArea.String;
            endText = strcat(repmat('*', 1, 25), ' End comments ', repmat('*', 1, 25));
            comments = sprintf('\n%s \n%s', text, endText);
            try
               import sa_labs.common.DaqLogger;
               DaqLogger.setLogging(logging.logging.INFO);
               DaqLogger.log(comments);
            catch x
                obj.log.debug(x.message, x);
                obj.commentsView.showError(x.message);
                return;
            end
            obj.stop();
        end
        
        function onViewSelectedCancel(obj, ~, ~)
            obj.stop();
        end
    end
end

