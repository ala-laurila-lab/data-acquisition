classdef IntensityCalibration < symphonyui.ui.Module
    
    properties (Constant)
        UNITS = containers.Map({ 'milli watt', 'micro watt'}, {10 ^-3, 10^-6});
    end
    
    properties (Access = private)
        deviceListBox
        ledTypeListBox
        powerUnitListBox
        spotSize
        ledCurrent
        CalibratedByText
        powerMeasured
        powerExponent
        notes
    end
    
    properties (Access = private)
        stimulsDevice
    end
    
    methods
        
        function createUi(obj, figureHandle)
            import appbox.*;
            
            set(figureHandle, ...
                'Name', 'Intensity Calibration', ...
                'Position', screenCenter(300, 320));
            
            mainLayout = uix.VBox( ...
                'Parent', figureHandle, ...
                'Padding', 11, ...
                'Spacing', 11);
            calibrationLayout = uix.Grid( ...
                'Parent', mainLayout, ...
                'Spacing', 8);
            
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Device:');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'LED Type:');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Spot size:');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Led current');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'CalibratedBy:');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Power:');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Unit:');
            Label( ...
                'Parent', calibrationLayout, ...
                'String', 'Notes:');
            
            obj.deviceListBox = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'popup', ...
                'Callback',  @obj.onSelectedDevice);
            obj.ledTypeListBox = uicontrol( ...
                'Parent', calibrationLayout, ...
                'Style', 'popup', ...
                'Callback',  @obj.onSelectedLed);
            
            obj.spotSize = uicontrol( ...
                'Parent', calibrationLayout, ...
                'Style', 'edit', ...
                'Enable', 'Off' ,...
                'HorizontalAlignment', 'left');
            
            obj.ledCurrent = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'Edit', ...
                'Enable', 'Off' ,...
                'HorizontalAlignment', 'left');
            
            obj.CalibratedByText = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'Edit', ...
                'HorizontalAlignment', 'left');
            
            obj.powerMeasured = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'Edit', ...
                'HorizontalAlignment', 'left');

            obj.powerUnitListBox = uicontrol( ...
                'Parent', calibrationLayout, ...
                'Style', 'popup', ...
                'String', cellstr(obj.UNITS.keys) );
            
            obj.notes = uicontrol( ...
                'Parent', calibrationLayout, ...
                'style', 'Edit', ...
                'HorizontalAlignment', 'left');                        
            set(calibrationLayout, ...
                'Widths', [110 -1 ], ...
                'Heights', [23 23 23 23 23 23 23 23]);
            
           
            buttonLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
                  
            uicontrol( ...
                'Parent', buttonLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Save', ...
                'Callback',  @obj.onSave);
            uicontrol( ...
                'Parent', buttonLayout, ...
                'Style', 'pushbutton', ...
                'String', 'View data', ...
                'Callback',  @obj.onViewData);
            set(buttonLayout, 'Widths', [120 120]);
            set(mainLayout, 'Heights', [250 30 ]);
        end
        
    end
    
    methods (Access = protected)
        
        function willGo(obj)
            obj.populateDeviceAndLed();
        end
        
        function didGo(obj)
            a = obj.acquisitionService;
            obj.addListener(a, 'SetProtocolProperties', @obj.onServiceSetProtocol);
            obj.addListener(a, 'SelectedProtocol', @obj.onServiceSetProtocol);
            obj.setPropertiesFromProtocol();   
        end
        
    end
    
    methods (Access = private)
        
        function populateDeviceAndLed(obj)
            
            devices = obj.configurationService.getDevices();
            obj.stimulsDevice = containers.Map();
            
            ledTypes = {};
            for i = 1 : numel(devices)
                if strfind(devices{i}.name, 'Stage')
                    obj.stimulsDevice(devices{i}.name) = devices{i}.getConfigurationSetting('ledTypes');
                elseif strfind(lower(devices{i}.name), 'led')
                    ledTypes{end + 1} = devices{i}.name; %#ok
                end
            end
            
            if ~ isempty(ledTypes)
                obj.stimulsDevice('LED') = ledTypes;
            end
            set(obj.deviceListBox, 'String', obj.stimulsDevice.keys);
            
            deviceName = obj.getSelectedDevice();
            set(obj.ledTypeListBox, 'String', obj.stimulsDevice(deviceName));
        end
        
        function onServiceSetProtocol(obj, ~, ~)
            obj.setPropertiesFromProtocol();
        end
        
        function setPropertiesFromProtocol(obj)
            if(~ obj.hasCalibrationSpotProtocolSelected())
                obj.view.showError('Please select and run calibration spot protocol');
                set(obj.spotSize, 'String', '');
                set(obj.ledCurrent, 'String', '');
                return
            end
            desc = obj.acquisitionService.getProtocolPropertyDescriptors();
            set(obj.spotSize, 'String', strcat(num2str(desc.findByName('spotSize').value), ' um'));
            set(obj.ledCurrent, 'String', desc.findByName('blueLED').value);
        end

        function tf = hasCalibrationSpotProtocolSelected(obj)
            a = obj.acquisitionService;
            tf = ~ isempty(strfind(a.getSelectedProtocol(), 'CalibrationSpot'));
        end
        
        function d = getSelectedDevice(obj)
            index = get(obj.deviceListBox, 'Value');
            devices = obj.deviceListBox.String;
            d = devices{index};
        end
        
        function d = getSelectedLed(obj)
            index = get(obj.ledTypeListBox, 'Value');
            devices = obj.ledTypeListBox.String;
            d = devices{index};
        end
        
        function e = getPowerExponent(obj)
            index = get(obj.powerUnitListBox, 'Value');
            values = obj.UNITS.values;
            e = values{index};
        end
        
        function onSave(obj, ~, ~)
            intensity = struct();
            intensity.device = obj.getSelectedDevice();
            intensity.ledType = obj.getSelectedLed();
            intensity.spotSize = get(obj.spotSize, 'String');
            intensity.ledCurrent = get(obj.ledCurrent, 'String');
            intensity.calibratedBy = get(obj.CalibratedByText, 'String');
            intensity.calibrationDate = char(datetime);
            intensity.power = str2double(get(obj.powerMeasured, 'String'));
            intensity.powerExponent = obj.getPowerExponent();
            intensity.unit = 'watt';
            
            % validate and show err if some is missing
            % Save the results to json file
            id =[matlab.lang.makeValidName(intensity.ledType) '' matlab.lang.makeValidName(intensity.spotSize)];
            name = [matlab.lang.makeValidName(char(datetime)) '_' id '-intensity.json'];
            location = [fileparts(which('aalto_rig_calibration_data_readme')) filesep 'intensity'];
            savejson('', intensity, [location filesep 'json' filesep name]);
            
            if(strcmp(intensity.spotSize, '500 um'))
                savejson('', intensity, [location filesep 'latest.json']);
            end
        end
        
        function onViewData(obj, ~, ~)
            location = [fileparts(which('aalto_rig_calibration_data_readme')) filesep 'intensity'];
            intensity = dir(fullfile(location, 'json'));
            data = {};

            for i = 3 : length(intensity)
                data{end + 1} = loadjson(fullfile(location,  'json', intensity(i).name));
                data{end}.calibrationDate = datetime(data{end}.calibrationDate, 'InputFormat', 'dd-MMM-yyyy hh:mm:ss');
            end
            struct2table([data{:}])
        end

    end
end
