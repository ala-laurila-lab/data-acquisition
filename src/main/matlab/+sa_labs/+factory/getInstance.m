function [instance, ctxt] = getInstance(name)

instance = [];

persistent context;
try
    if isempty(context)
        context = struct();
        context.mdepinInstances = mdepin.getBeanFactory(which('AcquisitionContext.m'));
        context.daqLogger = [];
        context.daqUILogger = [];
    end
    
    if isempty(name)
        ctxt = context;
        return
    end
    
    switch name
        case 'daqLogger'
            shouldCreateLog = true;
            [instance, context] = getDaqLogger(context, name, shouldCreateLog);
        case 'daqUILogger'
            shouldCreateLog = false;
            [instance, context] = getDaqLogger(context, name, shouldCreateLog);
        otherwise
            instance = context.mdepinInstances.getBean(name);
    end
    
catch exception
    disp(['Error getting instance (' name ') ' exception.message]);
end
ctxt = context;
end

function logDir = createLogDirIfNotExist()
logDir = [userpath() filesep '.daq_logs' filesep];
if ~ exist(logDir, 'dir')
    mkdir(logDir);
end
end

function [instance, context] = getDaqLogger(context, name, shouldCreateLog)

if ~ isempty(context.(name))
    instance = context.(name);
    return;
end

if ~ shouldCreateLog
    instance = sa_labs.common.DaqLogger(name);
    instance.setCommandWindowLevel(logging.logging.OFF);
    instance.setLogLevel(logging.logging.OFF);
    context.(name) = instance;
    return;
end

logDir = createLogDirIfNotExist();
instance = sa_labs.common.DaqLogger(name, ...
    'path', [logDir matlab.lang.makeValidName(datestr(datetime)) '.log'], ...
    'logLevel', logging.logging.INFO);
instance.setCommandWindowLevel(logging.logging.OFF);
instance.setLogLevel(logging.logging.OFF);
context.(name) = instance;
end