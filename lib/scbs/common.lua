-- contains common code for internal usage

local scbs = {}

function scbs.getext(path, split)
    local index = nil
    for i = #path, 1, -1 do
        if path:sub(i, i) == '.' then
            index = i
            break
        end
    end
    if not index then
        return nil
    end
    
    local ext = string.sub(path, index + 1)
    if split ~= true then
        return ext
    end
    return ext, string.sub(path, 1, index - 1)
end

function scbs.globalize(obj)
    for k, v in pairs(obj) do
        _G[k] = v;
    end
end

return scbs;
