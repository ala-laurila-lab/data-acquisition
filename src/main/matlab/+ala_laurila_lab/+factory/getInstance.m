function [instance, ctxt] = getInstance(name)

instance = [];
persistent context;
try
    if isempty(context)
        context = mdepin.getBeanFactory(which('AcquisitionContext.m'));
    end
    
    if isempty(name)
        ctxt = context;
        return
    end
    instance = context.getBean(name);
    
catch exception
    disp(['Error getting instance (' name ') ' exception.message]);
end
ctxt = context;
end

