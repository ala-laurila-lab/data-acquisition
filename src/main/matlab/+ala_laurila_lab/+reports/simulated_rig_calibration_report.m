service = ala_laurila_lab.factory.getInstance('calibrationService');
service.dataPersistence = 'simulated-rig-data';
service.logPersistence = 'simulated-rig-log';

date = service.getLastCalibrationDate('ala_laurila_lab.entity.LinearityMeasurement', 'LCRBlueLed_1000');
linearity = service.getLinearityByStimulsDuration(1000, 'LCRBlueLed');