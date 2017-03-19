service = ala_laurila_lab.factory.getInstance('calibrationService');
service.dataPersistence = 'simulated-rig-data';
service.logPersistence = 'simulated-rig-log';

linearity = service.getLinearityByStimulsDuration(1000, 'LCRBlueLed');