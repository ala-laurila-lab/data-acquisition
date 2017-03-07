function [instance, ctxt] = getInstance(name)

instance = [];
persistence context;
try
    if isempty(context)
        context = mdepin.getBeanFactory(which('AcquisitionContext.m'));
    end
    
    if isempty(name)
        return
    end
    instance = context.getBean(name);
    
catch exception
    disp(exception.message);
end
ctxt = context;
end

