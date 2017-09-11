% Loading dependecy without updates and console

[projectPath, configPath, projectParent] = tbLocateProject('data-acquisition');

depdendency = {TbIncludeStrategy.resolveIncludedConfigs(tbReadConfig('configPath', configPath), tbParsePrefs()).name};
cellfun(@(d) tbAddToPath(tbLocateToolbox(d)), depdendency, 'UniformOutput', false);

% start the stage server if the second instance is not running

[~, result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh');
if length(regexpi(result, '\w*Matlab.exe\w*')) < 2
    !matlab -nodesktop -nosplash -r "info = matlab.apputil.getInstalledAppInfo; addpath(genpath(info(ismember({info.name}, 'Symphony')).location)); tbAddToPath(tbLocateProject('data-acquisition')); matlab.apputil.run(info(ismember({info.name}, 'Stage Server')).id);" &
end

mpaRoot = tbLocateToolbox('matlab-persistence');
if ~ isempty(mpaRoot)
    javaaddpath(fullfile(mpaRoot, 'lib', 'mpa-jutil-0.0.1-SNAPSHOT.jar'));
    javaaddpath(fullfile(mpaRoot, 'lib', 'java-uuid-generator-3.1.4.jar'));
end

tbAddToPath(projectPath);