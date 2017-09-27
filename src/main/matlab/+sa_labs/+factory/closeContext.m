function closeContext()
    [~, ctxt] = sa_labs.factory.getInstance('');
%   cellfun(@(prop) delete(ctxt.(prop)), fields(ctxt));
    clear('ctxt');
end

