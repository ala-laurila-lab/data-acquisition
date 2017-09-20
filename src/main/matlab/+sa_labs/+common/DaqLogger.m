classdef DaqLogger < logging.logging
    
    events (NotifyAccess = private)
        MessageLogged
    end
 
    
    properties (Constant)
        LOG_FORMAT = '%-23s %s\n'
    end
    
    methods
        function obj = DaqLogger(varargin)
            obj@logging.logging(varargin{:});
            obj.logfmt = obj.LOG_FORMAT;
        end
        
        function writeLog(obj, level, ~, message)
            level = obj.getLevelNumber(level);
            
            if obj.commandWindowLevel_ <= level || obj.logLevel_ <= level
                timestamp = datestr(now, obj.datefmt_);
                logline = sprintf(obj.logfmt, timestamp, obj.getMessage(message));
            end
            
            if obj.commandWindowLevel_ <= level
                if obj.using_terminal
                    level_color = obj.level_colors(level);
                else
                    level_color = obj.level_colors(logging.logging.INFO);
                end
                fprintf(obj.logcolors(level_color), logline);
            end
            
            if obj.logLevel_ <= level && obj.logfid > -1
                fprintf(obj.logfid, logline);
                notify(obj, 'MessageLogged', symphonyui.app.AppEventData(logline));
            end
        end
        
        function [caller, line] = getCallerInfo(obj, ref)
            caller = [];
            line = [];
            % bypass dbstack check
            % do nothing;
        end
    end
end

