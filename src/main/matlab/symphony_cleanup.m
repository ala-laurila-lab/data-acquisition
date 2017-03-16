ala_laurila_lab.factory.closeContext();

if ~ isempty(tbLocateToolbox('matlab-persistence'))
    javarmpath(fullfile(tbLocateToolbox('matlab-persistence'), 'lib', 'mpa-jutil-0.0.1-SNAPSHOT.jar'));
    javarmpath(fullfile(tbLocateToolbox('matlab-persistence'), 'lib', 'java-uuid-generator-3.1.4.jar'));
end