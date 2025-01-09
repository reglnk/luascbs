-- contains basic definitions that may be used in writing project file

scbs = scbs or {}

scbs.OS = SCBS_OS;
scbs.ARCH = SCBS_ARCH;

scbs.VERBOSITY = 3

function scbs:error(...)
	error(...)
end
function scbs:print(...)
	if self.VERBOSITY < 1 then return end
	print("[message]", ...)
end
function scbs:vprint(...)
	if self.VERBOSITY < 2 then return end
	print("[detail] ", ...)
end
function scbs:debugprint(...)
	if self.VERBOSITY < 3 then return end
	print("[debug]  ", ...)
end

table.__index = table;
setmetatable(table, {__call = function(self, t) return setmetatable(t, self) end})

scbs.binType = table {
	app = {},
	shared = {},
	static = {},
	obj = {} -- unsure whether its needed but maybe some targets would need to compile to .o
}

local project = {}
project.__index = project;
setmetatable(project, {__call = function(self, t) return setmetatable(t or {}, self) end})
scbs.project = project;

local target = {}
target.__index = target;
setmetatable(target, {__call = function(self, t) return setmetatable(t or {}, self) end})
scbs.target = target;

-- like target but isn't related to any toolchains
-- helps when something needs to be copied, moved, generated etc.
local action = {
	__call = function(self, proj)
		self:__call(proj)
	end
};
setmetatable(action, {
	-- __index = action,
	__call = function(self, obj)
		if obj == nil or type(obj) == "table" then
			return setmetatable(obj, self);
		end
		local t = {__call = obj}
		return setmetatable(t, self);
	end
}); 
scbs.action = action;

-- @todo protection from recursion loop
function project:resolve_deps(deps, depth)
	if not deps then return end
	depth = depth or 0
	if depth > 100 then
		error("recursion depth limit reached");
	end
	for i, v in ipairs(deps) do
		if getmetatable(v) == action then
			self:resolve_deps(v.deps, depth + 1);
			v(self);
		elseif getmetatable(v) == target then
			self:resolve_deps(v.deps, depth + 1);
			self.toolchain.build(v);
		end
	end
end

function scbs.divpath(s)
	local sl = s:find("/[^/]*$") -- last slash position
	if not sl then return s end
	return s:sub(sl + 1), s:sub(1, sl)
end

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
    if not split then
        return ext
    end
    return ext, string.sub(path, 1, index - 1)
end

-- @todo remove
function scbs.globalize(obj)
    for k, v in pairs(obj) do
        _G[k] = v;
    end
end

return scbs