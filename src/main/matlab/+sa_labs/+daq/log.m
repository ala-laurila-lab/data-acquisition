function log(message)

daqlogger = sa_labs.factory.getInstance('daqLogger');
daqUIlogger = sa_labs.factory.getInstance('daqUILogger');

daqlogger.info(message);
daqUIlogger.info(message);
end

