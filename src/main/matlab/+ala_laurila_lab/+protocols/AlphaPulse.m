classdef AlphaPulse < sa_labs.protocols.BaseProtocol
    properties
        outputAmpSelection = 1
        preTime = 500         % pre-stimulus time (ms)
        stimTime = 1500       % stimulus duration (ms) - min = numberOfPulses*(pulseSeparation+(tau*4))
        tailTime = 500        % post-stimulus time (ms)
        amplitude = 28        % peak amplitude of dim flash response (pA)
        tau = 50              % kinetics of dim flash response - best fit to experiments = 50 (ms)
        numberOfPulses = 2    % number of dim flash responses in the train of pulses - max 10
        stepChange = 45       % step increment/decrement in peak amplitude or inter-pulse separation (pA or ms)
        pulseSeparation = 1000 % pulse's onset delay after preceeding pulse (ms)
        numberOfEpochs = 5    % number of epochs
        seedStartValue = 1    % initial level
        seedChangeMode = 'separation'; % either step through increasing peak amplitudes or through shorter seperation between pulses
    end
    
    properties (Hidden)
        responsePlotMode = 'cartesian'
        responsePlotSplitParameter = ''; %'pulseAmplitude';
        seedChangeModeType = symphonyui.core.PropertyType('char', 'row', {'amplitude', 'separation'});
        randomSeed;
    end
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.BaseProtocol(obj);
        end       

        function stim = createAmpStimulus(obj, ampName)
            
            sample_rate = obj.sampleRate;
            prestim_wave = repelem(0, obj.preTime * sample_rate / 1E3);
            tailstim_wave = repelem(0, obj.tailTime * sample_rate / 1E3);            
            n_stimpoints = obj.stimTime * sample_rate / 1E3;
            n_totalpoints = length(prestim_wave) + length(tailstim_wave) + n_stimpoints;
            
            if obj.numberOfPulses <= 1
                x = 0:obj.stimTime/n_stimpoints:obj.stimTime-obj.stimTime/n_stimpoints;
                stim_wave = obj.amplitude .* (x / obj.tau) .* exp(1 - x / obj.tau);
                %Assemble waveform & add amplifier's holding potential
                totalWave = horzcat(prestim_wave, stim_wave, tailstim_wave) + obj.rig.getDevice(ampName).background.quantity;
            else
                n_sepoints = obj.pulseSeparation * sample_rate / 1E3;
                stim_matrix = zeros(obj.numberOfPulses,n_totalpoints);
                for i=1:obj.numberOfPulses
                    x = 0:obj.stimTime/n_stimpoints:obj.stimTime-obj.stimTime/n_stimpoints;
                    stim_wave = obj.amplitude .* (x / obj.tau) .* exp(1 - x / obj.tau);
                    if i > 1
                        prime_wave = [zeros(1,n_sepoints*i),stim_wave];
                        stim_wave = prime_wave(n_sepoints:n_stimpoints+n_sepoints-1);
                    end
                    stim_matrix(i,:) = horzcat(prestim_wave, stim_wave, tailstim_wave);
                end
                %Assemble waveform & add amplifier's holding potential
                totalWave = sum(stim_matrix) + obj.rig.getDevice(ampName).background.quantity;
            end
            
            %Create Waveform stimulus
            gen = symphonyui.builtin.stimuli.WaveformGenerator();
            gen.sampleRate = obj.sampleRate;
            gen.units = obj.rig.getDevice(ampName).background.displayUnits;
            gen.waveshape = totalWave;
            stim = gen.generate();
        end
        
        function prepareEpoch(obj, epoch)
            
            prepareEpoch@sa_labs.protocols.BaseProtocol(obj, epoch);
            outputAmpName = sprintf('amp%g', obj.outputAmpSelection);

            % step through increasing peak amplitudes
            if strcmp(obj.seedChangeMode, 'amplitude')
                seed = obj.seedStartValue;
                obj.randomSeed = seed;
                obj.amplitude = obj.amplitude + obj.stepChange * seed;

            % step through decreasing inter-pulse separations
            elseif strcmp(obj.seedChangeMode, 'separation')
                seed = obj.seedStartValue;
                obj.randomSeed = seed;
                obj.pulseSeparation = obj.pulseSeparation + ( obj.stepChange * (seed - obj.numberOfEpochs) );
                
            end
            epoch.addParameter('randomSeed', obj.randomSeed);
            epoch.addStimulus(obj.rig.getDevice(outputAmpName), obj.createAmpStimulus(outputAmpName));          
        end       
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
        function completeRun(obj)
            % Enforce clearing of the last values modified
            obj.preTime=[];obj.stimTime=[];obj.tailTime=[];obj.pulseSeparation=[];obj.amplitude=[];
        end
        
    end
end