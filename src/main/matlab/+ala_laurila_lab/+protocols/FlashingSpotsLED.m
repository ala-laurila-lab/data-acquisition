classdef FlashingSpotsLED < sa_labs.protocols.StageProtocol ...
                       & sa_labs.common.ProtocolLogger
    % =========================================================================
    %  Flashes a centred spot while sweeping intensity, meanLevel, (duration) and LED
    %  current.  LED current is changed once per epoch in prepareEpoch.
    %  A new GUI selector "Flash intensity" (0.1, 0.5, 1, 10, 100) sets
    %  stimulus-specific intensity, LED current and meanLevel tables.
    % =========================================================================

    %% ------------------------------ USER SETTABLE ---------------------------
    properties
        % times in ms
        preTime     = 500;          % Spot leading duration (ms)
        stimTime    = 16.7;         % Base stim duration used to build sweep (ms)
        tailTime    = 1000;         % Spot trailing duration (ms)

        spotSize    = 200;          % Spot diameter (µm)

        bgPatchSize = 500;
        
        numberOfRepetions = 15;     % How many cycles
        randomOrdering    = false;  % random presentation order

        % GUI selector -------------------------------------------------------
        % NOTE  Stage shows property names as labels, so "flashIntensity" will
        %       appear as "Flash Intensity" in the UI.  Allowed values:
        %       0.1, 0.5, 1, 10, 100
        lowestFIntensity = '0.1'
        %startFlashIntensity = 0.1;
        %flashIntensity = 10;         % (scalar) selector for tables below

        % These default vectors are placeholders; prepareRun overwrites them
        %ledCurrents = [101 50 100 20];   % LED current sweep (0-255)
    end

    %% ---------------------------- INTERNAL STATE ---------------------------
    properties (Hidden)
        %startFlashIntensityType = symphonyui.core.PropertyType('char','row', {'0.1', '0.5', '1', '10', '100'});
        flashIntensities
        lowestFIntensityType = symphonyui.core.PropertyType('char','row',{'0.1', '0.5', '1', '10'});
        %lowestFIntensityType = symphonyui.core.PropertyType('denserealdouble','row',[0.1, 0.5, 1, 10, 100]);
        startFlashIntensity = 0.1;
        
        version = 5;                % bumped after GUI selector addition; get rid of durations sweep

        combos                     % Array of [iIdx dIdx ledIdx] rows
        numberOfCombinations
        order                      % current presentation order (row indices)
        blockLengths               % length of each block
        offsets                    % starting index of each block in flat vector
        combIdx                    % index into flat vectors
        durations
        duration
        intensity
        spotSizes
        size
        ledCurrent
        
        % master stimulus tables (cells)
        %masterIntensities
        %masterCurrents
        %masterMeans
        
        % flatten vectors used this run
        intensities
        ledCurrents
        meanLevels
        lowestFlashIntensity
        buildBlockOrder
     
        responsePlotMode  = 'cartesian';
        responsePlotSplitParameter = 'combIdx';
    end

    properties (Hidden, Dependent)
        totalNumEpochs
    end

    methods
    %% --------------------------- RUN LEVEL HOOKS ---------------------------

        function didSetRig(obj)                        % (optional)
            didSetRig@sa_labs.protocols.StageProtocol(obj);

            % Default LED current for "Show Stimulus"
            if ~isempty(obj.ledCurrents)
                obj.blueLED = obj.ledCurrents(1);
            end
        end

        function prepareRun(obj)
            
            %obj.lowestFlashIntensity = str2double(obj.astartFlashIntensity);
            obj.startFlashIntensity = str2double(obj.lowestFIntensity);
            %obj.lowestFlashIntensity = obj.startFlashIntensity;
                       
%             masterIntensities = {
%                 [0.024, 0.031, 0.290, 0.624], ...           % 0.1R
%                 [0.231, 0.031, 0.102, 0.137, 0.976], ...    % 0.5R
%                 [0.452, 0.192, 0.432, 0.788, 0.980], ...    % 1R
%                 [0.941, 0.941, 0.976, 0.992, 1]};             % 10R
%             
%             masterMeans = {
%                 [0.004, 0.020, 0.275, 0.620], ...
%                 [0.008, 0.008, 0.078, 0.133, 0.973], ...
%                 [0.008, 0.027, 0.275, 0.745, 0.973], ...                
%                 [0.016, 0.016, 0.141, 0.620, 0.925]};
%             
%             
%             masterCurrents = {
%                 [12, 15, 13, 31], ...
%                 [10, 26, 26, 159, 166], ...
%                 [10, 13, 13, 27, 160], ...
%                 [17, 17, 18, 31, 180]};
            
            % for laser background full range
%           masterIntensities = {
%                 [0.009, 0.009, 0.009, 0.009,  0.009], ...   % 0.1
%                 [0.046, 0.046, 0.046, 0.046, 0.046], ...    % 0.5
%                 [0.093, 0.093, 0.093, 0.093, 0.093], ...    % 1
%                 [0.927, 0.927, 0.927, 0.927, 0.927], ...    % 10
%                 [1, 1, 1, 1, 1]};                           % 100
%             
%             masterMeans = {
%                 [0, 0, 0, 0.1, 0.5], ...
%                 [0, 0, 0, 0.1, 0.5], ...
%                 [0, 0, 0, 0.1, 0.5], ...
%                 [0, 0, 0, 0.1, 0.5], ...
%                 [0, 0, 0, 0.1, 0.5]};
%             
%             masterCurrents = {
%                 [17, 17, 17, 17, 17], ...
%                 [17, 17, 17, 17, 17], ...
%                 [17, 17, 17, 17, 17], ...
%                 [17, 17, 17, 17, 17], ...
%                 [118, 118, 118, 118, 118]};


            % for laser background NARROW range
            masterIntensities = {
                [0.009, 0.009, 0.009, 0.009,  0.009], ...   % 0.1
                [0.046, 0.046, 0.046, 0.046, 0.046], ...    % 0.5
                [0.093, 0.093, 0.093, 0.093, 0.093]};       % 1
            
            masterMeans = {
                [0, 0, 0, 0.1, 0.5], ...
                [0, 0, 0, 0.1, 0.5], ...
                [0, 0, 0, 0.1, 0.5]};
            
            masterCurrents = {
                [17, 17, 17, 17, 17], ...
                [17, 17, 17, 17, 17], ...
                [17, 17, 17, 17, 17]};
            
            %switch obj.lowestFlashIntensity
            %    case 0.1
            %        obj.intensities = [0.024, 0.031, 0.290, 0.624];
            %        obj.ledCurrents = [12, 15, 13, 31];
            %        obj.meanLevels   = [0.004, 0.020, 0.275, 0.620];
            %    case 0.5
            %        obj.intensities = [0.231, 0.031, 0.102, 0.137, 0.976];
            %        obj.ledCurrents = [10, 26, 26, 159, 166];
            %        obj.meanLevels   = [0.008, 0.008, 0.078, 0.133, 0.973];
            %    case 1
            %        obj.intensities = [1, 0.1, 1, 0.5, 1];
            %        obj.ledCurrents = [101, 101, 101, 101, 101];
            %        obj.meanLevels   = [0.1, 1, 0.1, 1, 0.2];
            %    case 10
            %        obj.intensities = [0.941, 0.976, 0.992, 1];
            %        obj.ledCurrents = [17, 18, 31, 180];
            %        obj.meanLevels   = [0.016, 0.141, 0.620, 0.925];
            %    case 100
            %        obj.intensities = [1, 1, 1, 1];
            %        obj.ledCurrents = [12, 12, 12, 12];
            %        obj.meanLevels   = [0, 0, 0, 0];
            %    otherwise
            %        error('FlashSpotsLED:UnknownSelection', ...
            %              'flashIntensity must be one of: 0.1, 0.5, 1, 10, 100');
            %end
            
            % Apply starting iflash intensity trimming
            obj.flashIntensities = [0.1 0.5 1 10];
            idxStart = find(abs(obj.flashIntensities - obj.startFlashIntensity) < 1e-9, 1, 'first');
            if isempty(idxStart)
                error('flashIntensity must be one of 0.1, 0.5, 1, 10, 100');
            end
            
            masterIntensities = masterIntensities(idxStart:end);
            masterCurrents = masterCurrents(idxStart:end);
            masterMeans = masterMeans(idxStart:end);
            
            
            % flatten tables into vectors but remember block lengths
            obj.intensities = [masterIntensities{:}];
            obj.ledCurrents = [masterCurrents{:}];
            obj.meanLevels = [masterMeans{:}];
            
            obj.blockLengths = cellfun(@numel, masterIntensities);
            obj.offsets = cumsum ([0 obj.blockLengths(1:end-1)]); % start index per block
                       
            % ----------------------------------------------------------------
            % Standard prepareRun duties (unchanged except vectors) ------
            % ----------------------------------------------------------------
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            % Build epoch order
            obj.order = [];
            maxRows = max(obj.blockLengths);
            nBlocks = numel(obj.blockLengths);

            for r = 1:maxRows
                % decide block traversal order for *this row*
                if obj.randomOrdering
                    blockIdx = randperm(nBlocks);
                else
                    blockIdx = 1:nBlocks;
                end
                for b = blockIdx
                    if r <= obj.blockLengths(b)
                        obj.order(end+1) = obj.offsets(b) + r;
                    end
                end
            end
            
            obj.order = repelem(obj.order, obj.numberOfRepetions);
            obj.numberOfCombinations = numel(obj.order);
            
            % duration sweep is unchanged
            %obj.durations   = obj.stimTime * 2.^(4:-1:0);
            obj.durations   = obj.stimTime * ones(1, numel(obj.intensities));
            obj.spotSizes   = obj.spotSize * ones(1, numel(obj.intensities));
        end

    %% ----------------------------- EPOCH LEVEL -----------------------------
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);

            index = mod(obj.numEpochsPrepared, obj.numberOfCombinations) + 1;

            obj.combIdx = obj.order(index);

            obj.intensity  = obj.intensities(obj.combIdx);
            obj.meanLevel  = obj.meanLevels(obj.combIdx);
            obj.duration   = obj.durations(obj.combIdx);
            obj.size       = obj.spotSizes(obj.combIdx);
            obj.stimTime   = obj.duration;

            dev = obj.rig.getDevice('LightCrafter');
            %dev.setBackgroundConfiguration('singlePattern', obj.meanLevel, 1);
            dev.setBackgroundConfiguration('singlePattern', 0, 1);
            
            % LED current for this epoch
            obj.ledCurrent = obj.ledCurrents(obj.combIdx);
            dev = obj.rig.getDevice('LightCrafter');
            dev.setLedCurrents(0, 0, obj.ledCurrent, 0);   % only blue active
            pause(0.2);

            %disp ([obj.intensity obj.meanLevel obj.ledCurrent]);
            % Store parameters
            epoch.addParameter('combIdx',   obj.combIdx);
            epoch.addParameter('intensity', obj.intensity);
            epoch.addParameter('duration',  obj.duration);
            epoch.addParameter('size',      obj.size);
            epoch.addParameter('blueLED',   obj.ledCurrent);
            epoch.addParameter('meanLevel', obj.meanLevel);

            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
        end

    %% ---------------------- PRESENTATION CONSTRUCTION ----------------------
        function p = createPresentation(obj)
            totalTime = (obj.preTime + obj.stimTime + obj.tailTime) * 1e-3;
            p = stage.core.Presentation(totalTime);

            % ---------- background patch ------------------------------------------
            bg              = stage.builtin.stimuli.Rectangle();
            % NEW — convert µm to pixels
            patchPix        = round(obj.um2pix(obj.bgPatchSize));  % scalar or 1×2
            bg.size         = patchPix .* [1 1];   % ensure 1×2 even for scalar
            bg.position     = obj.rig.getDevice('Stage').getCanvasSize() / 2;
            bg.color        = obj.meanLevel;
            bg.opacity      = 1;
            p.addStimulus(bg);
            
            spot              = stage.builtin.stimuli.Ellipse();
            spot.radiusX      = round(obj.um2pix(obj.size / 2));
            spot.radiusY      = spot.radiusX;
            spot.color        = obj.intensity;
            canvasSize        = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position     = canvasSize / 2;
            spot.opacity      = 1;
            p.addStimulus(spot);

            obj.setOnDuringStimController(p, spot);

            % shared code for multi-pattern objects
            obj.setColorController(p, spot);
            
            % Call for backgrounds be set between stimulus presentations
            %obj.changeStimIntensityController(p, spot);
        end
        
        %function changeStimIntensityController(obj, p, stageObject)
        %    function c = changeDuringStim(state, preTime, stimTime, intensity, meanLevel)
        %        stim = (state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3);
        %        if stim
        %            c = intensity;
        %        else
        %            c = meanLevel;
        %        end
        %    end
        % 
        %    controller = stage.builtin.controllers.PropertyController(stageObject, 'color', ...
        %    @(s)changeDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
        %    p.addController(controller);
        %end
    %% ------------------------- HOUSEKEEPING/LIMITS -------------------------
        function n = get.totalNumEpochs(obj)
            %n = obj.numberOfRepetions * obj.numberOfCombinations;
            n = obj.numberOfCombinations; % for repetitons be consequtive in each intensity and background combination
        end

        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            dev = obj.rig.getDevice('LightCrafter');
            dev.setBackgroundConfiguration('singlePattern', obj.meanLevel, 1);
            dev.setLedCurrents(0, 0, 0, 0);   % only blue active
            pause(0.1);
            
           completeRun@sa_labs.protocols.StageProtocol(obj);
           obj.logCompleteRun();
        end
    end
end
