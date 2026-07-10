CassiniEnergyUtils = {}

function CassiniEnergyUtils:modulus(a,b)
    return a - math.floor(a/b)*b
end

function CassiniEnergyUtils:deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CassiniEnergyUtils:deepcopy(orig_key)] = CassiniEnergyUtils:deepcopy(orig_value)
        end
        setmetatable(copy, CassiniEnergyUtils:deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
