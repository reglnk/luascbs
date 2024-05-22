-- contains basic definitions that may be used in writing project file

local base = {}

base.binType = table {
	app = {},
	shared = {},
	static = {},
	obj = {} -- unsure whether its needed but maybe some targets would need to compile to .o
}

local project = {}
project.__index = project;
setmetatable(project, {__call = function(self, t) return setmetatable(t or {}, self) end});
base.project = project

local target = {}
target.__index = target;
setmetatable(target, {__call = function(self, t) return setmetatable(t or {}, self) end});
base.target = target

-- like target but isn't related to any toolchains
-- helps when something needs to be copied, moved, generated etc.
local action = {
	__call = function(self, proj)
		self:fn(proj)
	end
}
action.__index = action;
setmetatable(action, {
	__call = function(self, obj)
		if obj == nil or type(obj) == "table" then
			return setmetatable(obj, self);
		end
		local t = {fn = obj}
		return setmetatable(t, self);
	end
}); 
base.action = action

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

base.basepath = function(s)
	local sl = s:find("/[^/]*$") -- last slash position
	if not sl then return s end
	return s:sub(sl + 1)
end

base.divpath = function(s)
	local sl = s:find("/[^/]*$") -- last slash position
	if not sl then return s end
	return s:sub(sl + 1), s:sub(1, sl)
end

return base