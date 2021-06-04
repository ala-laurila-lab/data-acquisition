classdef NDFCalibration < symphonyui.ui.Module
    
    properties (Constant)
        UNITS = {'milli watt',  'micro watt' }
        SPOT_DIAMETER_FOR_PROJECTOR = 200 % micron
    end
    
    % UI handles
    properties (Access = private)
        ndfWheelIdListBox
        ndfListBox
        attenuationValue
        calibrateButton
        measurementTable
        nextCalibrationDateText
        CalibratedByText
        notesText
        statusLabel
    end
    
    properties (Dependent)
        ndfWheel
    end
    
    % Device handles
    properties (Access = private)
        optometer
        ndfWheels = sa_labs.devices.NeutralDensityFilterWheelDevice.empty(2, 0) 
        stimulusDevice % Can be light crafter or LED
        mode
    end
    
    methods
        
        function createUi(obj, figureHandle)
            import appbox.*;
            
            set(figureHandle, ...
                'Name', 'NDF Calibration', ...
                'Position', screenCenter(550, 250));
            
            mainLayout = uix.VBox( ...
                'Parent', figureHandle, ...
                'Padding', 11, ...
                'Spacing', 11);
            calibrationLayout = uix.Grid( ...
                'Parent', mainLayout, ...
                'Spacing', 7);

            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'NDF Wheel:');
            
            obj.ndfWheelIdListBox = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'popup', ...
                'Callback',  @obj.onSelectedNdfWheelId);
            
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'NDF Type:');
            
            obj.ndfListBox = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'popup', ...
                'Callback',  @obj.onSelectedNdf);
            
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Attenuation');
            
            obj.attenuationValue = Label( ...
                'Parent', calibrationLayout, ...
                'String', '1');
            
            set(calibrationLayout, ...
                'Widths', [65 65 65 65 100 -1 ], ...
                'Heights', [25]);
            
            measurementsLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
            
            obj.measurementTable = uiextras.jTable.Table(...
                'Parent', measurementsLayout,...
                'ColumnEditable', [true, true, true, true, true],...
                'ColumnName', {'Led Input','Power Measured', 'Unit', 'Power Without NDF', 'Unit'},...
                'ColumnFormat', {'integer', 'float', 'popup', 'float', 'popup'},...
                'CellEditCallback', @(h,d) obj.onEditMeasurent(h, d),...
                'CellSelectionCallback', @obj.onSetBackground,...
                'ColumnPreferredWidth',[10 25 5 25 5]);
            

            
            notesLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
            
            Label( ...
                'Parent', notesLayout, ...
                'String', 'Notes:');
            
            obj.notesText = uicontrol( ...
                'Parent', notesLayout, ...
                'style', 'Edit');
            set(notesLayout, 'Widths', [40 -1]);
            
            buttonLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
            
            obj.statusLabel = Label( ...
                'Parent', buttonLayout, ...
                'String', 'Info: ');
            
            uicontrol( ...
                'Parent', buttonLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Save', ...
                'Callback',  @obj.onSave);
            
            set(buttonLayout, 'Widths', [-1 60]);
            set(mainLayout, 'Heights', [25 -1 25 25]);
        end
        
    end
    
    methods
                
        function ndfWheel = get.ndfWheel(obj)
            id = obj.getSelectedNdfWheelId();
            ndfWheel = obj.ndfWheels(id);
        end
    end
    
    methods (Access = protected)
        
        function willGo(obj)
            
            obj.ndfWheels(1) = obj.configurationService.getDevice('neutralDensityFilterWheel1');
            obj.ndfWheels(2) = obj.configurationService.getDevice('neutralDensityFilterWheel2');
            set(obj.ndfWheelIdListBox, 'String', {'1' , '2'});
            
            obj.stimulusDevice = obj.getStimulsDevice();
            set(obj.measurementTable, 'Enabled', 'off');
            obj.populateMeasurementTable();
        end
        
        function bind(obj)
            bind@symphonyui.ui.Module(obj);
        end
        
        function didGo(obj)
            % set the default ndf to 1
            set(obj.ndfWheelIdListBox, 'Value', 1);
            obj.setNdfValues();
            obj.disableOptometerConnect();
        end
        
    end
    
    methods (Access = private)

        function onSelectedNdfWheelId(obj, ~, ~)
            obj.setNdfValues();
        end
        
        function setNdfValues(obj)
           
            ndfValues = obj.ndfWheel.getConfigurationSetting('filterWheelNdfValues');
            ndfAttenuation = obj.ndfWheel.getResource('filterWheelAttenuationValues');
            set(obj.ndfListBox, 'String', ndfValues(ndfAttenuation ~=1 ));
            set(obj.ndfListBox, 'Value', 1);
            obj.setNdf();
            obj.setNdfAttenuation()
        end
        
        function onSelectedNdf(obj, ~, ~)
            obj.setNdf();
            obj.setNdfAttenuation()
        end
        
        function setNdfAttenuation(obj)
            ndfAttenuation = obj.ndfWheel.getResource('filterWheelAttenuationValues');
            ndf = obj.getSelectedNdf();
            set(obj.attenuationValue, 'String', num2str(ndfAttenuation(ndf)));
        end
        
        function disableOptometerConnect(obj)
            set(obj.calibrateButton, 'Enable', 'off');
            set(obj.measurementTable, 'Enabled', 'on');
            obj.mode = 'manual';
            set(obj.statusLabel, 'String', 'Please start with manual calibration ...');
        end
        

        function populateMeasurementTable(obj)
            
            obj.measurementTable.ColumnFormatData{3} = obj.UNITS;
            obj.measurementTable.ColumnFormatData{5} = obj.UNITS;
            
            calibrationInput = obj.stimulusDevice.getConfigurationSetting('ndfCalibrationLedInput');
            
            obj.measurementTable.ColumnName{1} = strcat(obj.measurementTable.ColumnName{1}, '');
            obj.measurementTable.Data(1 : numel(calibrationInput), 1) = num2cell(calibrationInput);
            obj.measurementTable.SelectedRows = 1;
        end
        
        function onSetBackground(obj, ~, ~)
            
            if strcmp(obj.mode, 'manual')
                set(obj.measurementTable, 'Enabled', 'off');
                obj.setNdf();
                row = obj.measurementTable.SelectedRows;
                input = obj.measurementTable.Data{row, 1};
                obj.setBackground(input);
                set(obj.measurementTable, 'Enabled', 'on');
            end
        end
       
        
        function setBackground(obj, input)
            
            if obj.isProjector()
                obj.stimulusDevice.setLedCurrents(0, 0, input, 0);
            else
                background = obj.stimulusDevice.background;
                device.background = symphonyui.core.Measurement(input, obj.stimulusDevice.background.displayUnits);
                try
                    device.applyBackground();
                catch x
                    obj.stimulusDevice.background = background;
                    obj.view.showError(x.message);
                    return;
                end
            end
        end
        
        function onEditMeasurent(obj, ~, d)
            % If last edited column is 'unit' then alert
            % saying manual ndf has to be selected
            
            if ~ strcmp(obj.mode, 'manual'); return; end
            
            switch d.Indices(2)
                case 3
                    pause(0.1)
                    promptAndSetEmptyNdf();
                case 5
                    pause(0.1)
                    promptAndSetNdf();
                otherwise
                    return;
            end
            
            function promptAndSetEmptyNdf()
                
                if obj.ndfWheel.isManual()
                    obj.view.showMessage('Please ensure that NDF is set to Empty');
                end
                
                set(obj.measurementTable, 'Enabled', 'off');
                set(obj.statusLabel, 'String', 'As a next step. Setting the NDF to Empty');
                obj.setEmptyNdf();
                set(obj.statusLabel, 'String', 'Ready to measure the power for Empty ndf ...');
                set(obj.measurementTable, 'Enabled', 'on');
            end
            
            function promptAndSetNdf()
                
                if obj.ndfWheel.isManual()
                    obj.view.showMessage(['Please ensure that NDF is set to '  num2str(obj.getSelectedNdf()) ' .....']);
                end
                obj.setNdf();

            end
        end
        
        function onSave(obj, ~, ~)
            if(obj.validate())
                
                n = numel(obj.measurementTable.getColumnData(1));
                wheelId = obj.ndfWheel.getResource('wheelID');
                toExponent = @(ndfMeasurement, index) arrayfun(@(x) ndfMeasurement.toExponent(x), obj.measurementTable.getColumnData(index))';
                ndf = obj.getSelectedNdf();
                ndfMeasurement =  ala_laurila_lab.entity.NDFMeasurement( ['wheel' num2str(wheelId) 'ndf' num2str(ndf)]);
                ndfMeasurement.ledInput = cell2mat(obj.measurementTable.getColumnData(1))';
                ndfMeasurement.ledInputExponent = ones(1, n);
                % Power with ndf
                ndfMeasurement.powerWithNdf = cell2mat(obj.measurementTable.getColumnData(2))';
                ndfMeasurement.powerWithNdfExponent = toExponent(ndfMeasurement, 3);
                % Power without ndf
                ndfMeasurement.powers = cell2mat(obj.measurementTable.getColumnData(4))';
                ndfMeasurement.powerExponent = toExponent(ndfMeasurement, 5);
                ndfMeasurement.calibrationDate = char(date);
                % validate and show err if some is missing
                % Save the results to json file            
                name = [matlab.lang.makeValidName(char(datetime)), '-ndf' num2str(ndf) '-calibration.json'];
                location = [fileparts(which('aalto_rig_calibration_data_readme')) filesep 'ndf' filesep 'wheel' num2str(wheelId)];
                savejson('', ndfMeasurement, [location filesep name]);
                set(obj.statusLabel, 'String', ['Saved. Measured OD for ndf ' num2str(ndf) ' is ' num2str(ndfMeasurement.opticalDensity)]);
            end
        end
        
        function device = getStimulsDevice(obj)
            try
                device = obj.configurationService.getDevice('LightCrafter');
            catch exception %#ok
                device = obj.configurationService.getDevice('Led');
            end
        end
        
        function tf = isProjector(obj)
            tf = ~ isempty(strfind(obj.stimulusDevice.name, 'LightCrafter'));
        end
        
        function ndf = getSelectedNdf(obj)
            index = get(obj.ndfListBox, 'Value');
            ndfs = cellstr(obj.ndfListBox.String);
            ndf = str2double(ndfs{index});
        end
        
        function id = getSelectedNdfWheelId(obj)
            index = get(obj.ndfWheelIdListBox, 'Value');
            ids = cellstr(obj.ndfWheelIdListBox.String);
            id = str2double(ids{index});
        end 
        
        function ndfValue = setEmptyNdf(obj)
            for i = 1 : 2
                wheel = obj.ndfWheels(i);
                ndfValues = wheel.getConfigurationSetting('filterWheelNdfValues');
                ndfAttenuation = wheel.getResource('filterWheelAttenuationValues');
                ndfValues = ndfValues(ndfAttenuation == 1);
                ndfValue = ndfValues(1);
                wheel.setNdfValue(ndfValue);
            end
        end
        
        function setNdf(obj)
            ndf = obj.getSelectedNdf();
            set(obj.measurementTable, 'Enabled', 'off');
            set(obj.statusLabel, 'String', ['As a next step. Setting the NDF to ' num2str(ndf) ' ndf ....']);
            obj.ndfWheel.setNdfValue(ndf);
            set(obj.statusLabel, 'String', ['Ready to measure the power for ' num2str(ndf) ' ndf ...']);
            set(obj.measurementTable, 'Enabled', 'on');
        end
        
        function tf = validate(obj)
            tf = 0;
           
            inValid = @(var) any(cellfun(@isempty, var));
            
            if(inValid(obj.measurementTable.getColumnData(2)))
                obj.view.showError('Please ensure power is measured for all led input');
                return;
            end
            if(inValid(obj.measurementTable.getColumnData(3)))
                obj.view.showError('Please ensure that unit is selected for measured power');
                return;
            end
            if(inValid(obj.measurementTable.getColumnData(4)))
                obj.view.showError('Please ensure power is measured for all led input');
                return;
            end
            if(inValid(obj.measurementTable.getColumnData(5)))
                obj.view.showError('Please ensure that unit is selected for measured power');
                return;
            end
             tf = 1;
        end
    end
    
end
