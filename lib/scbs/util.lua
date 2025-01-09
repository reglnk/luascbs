--[[
@todo
luascbs may be used as library itself.
So it's reasonable to remove these modifications to standard library in favor of
making them available as lua functions and also as Luar operators, like

local lst = "my string" split (delim, limit);
local sym = "my string" at 0;
local subtab = {1, 2, 3, 4, 5} sub (2, 4);
local copy = subtab clone();
]]

function string.split(self, delim, limit)
	local arr = {}
	local iter = 1
	while iter <= #self do
		if limit then
			if limit == 0 then break
			else limit = limit - 1 end
		end
		local st, en = self:find(delim, iter)
		if st and en ~= 0 then
			local part = self:sub(iter, st - 1);
			if #part ~= 0 then table.insert(arr, part) end
			iter = en + 1
		else break end
	end
	local part = self:sub(iter, #self);
	if #part ~= 0 then table.insert(arr, part) end
	return arr
end

function string.at(self, pos)
	return self:sub(pos, pos);
end

function table.sub(self, b, e)
	local t = {}
	for i = b, e or #self do
		t:insert(self[i])
	end
	return t
end

function table.clone(self)
	local t = {}
	for k, v in pairs(self) do
		t[k] = v
	end
end
