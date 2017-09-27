classdef DaqLogger < logging.logging
    
    events (NotifyAccess = private)
        MessageLogged
    end
    
    properties (Access = private)
        headerBuilder
        headerMap
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
        
        function obj = appendHeader(obj, header)
            if isempty(obj.headerMap)
                obj.headerMap = containers.Map();
            end
            obj.headerMap(header) = char(repmat(' ', 1, length(header)));
        end
        
        function appendColumn(obj, header, column)
            if isKey(obj.headerMap, header)
               src = obj.headerMap(header);
               src(1 : length(column)) = column;
               obj.headerMap(header) = src;
            end
        end
    end
    
    methods (Static)
        
        function daqlogger = addLogTableHeader(header)
            daqlogger = sa_labs.factory.getInstance('daqLogger');
            daqlogger.appendHeader(header);
        end
        
        function daqlogger = addLogTableColumn(header, data)
            daqlogger = sa_labs.factory.getInstance('daqLogger');
            daqlogger.appendColumn(header, num2str(data));
        end
        
        function flushTable()
            daqlogger = sa_labs.factory.getInstance('daqLogger');
            daqlogger.headerMap = [];
        end
                
        function header = getHeader()
            daqlogger = sa_labs.factory.getInstance('daqLogger');
            header = strcat(daqlogger.headerMap.keys, '|');
            header = [header{:}];
            logLine = @(message) strcat(datestr(now, daqlogger.datefmt_), ' | ',message);
            borders = char(repmat('-', 1, length(header)));
            header = sprintf('\n%s \n%s \n%s', logLine(borders), logLine(header), logLine(borders));
        end
        
        function row = getCurrentRow()
            daqlogger = sa_labs.factory.getInstance('daqLogger');
            row = strcat(daqlogger.headerMap.values, '|');
            row = ['|' row{:}];
        end
        
        function log(message, varargin)
            
            daqlogger = sa_labs.factory.getInstance('daqLogger');
            daqUIlogger = sa_labs.factory.getInstance('daqUILogger');
            
            daqlogger.info(message);
            daqUIlogger.info(message);
        end
        
                
        function setLogging(level)
            daqLogger = sa_labs.factory.getInstance('daqUILogger');
            daqLogger.setLogLevel(level);
            
            daqLogger = sa_labs.factory.getInstance('daqLogger');
            daqLogger.setLogLevel(level);
        end
    end
end

