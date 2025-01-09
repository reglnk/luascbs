-- Created nearly 30 Mar 2024 at 19:12:51
-- by reglnk

local serialize = {}

local function escape(s)
	-- todo: optimize
	return (s
		:gsub("\\", "\\\\")
		:gsub("\"", "\\\"")
		:gsub("\n", "\\n")
		:gsub("\r", "\\r")
		:gsub("\t", "\\t")
		:gsub("\t", "\\v")
		:gsub("\t", "\\f")
	);
end

local function indent(depth)
	local tab = {}
	for i = 1, depth do
		tab[i] = "  "
	end
	return table.concat(tab)
end

function serialize.to_lua(obj, depth)
	if not depth then depth = 0 end
	local tp = type(obj)
	if tp == "table" then
		local strings = {}
		local comma = false
		table.insert(strings, "{")
		for k, v in pairs(obj) do
			if comma
			then table.insert(strings, ",")
			else comma = true end
			table.insert (strings, "\n" .. indent(depth + 1) ..
				"[" .. serialize.to_lua(k, depth + 1) .. "] = " ..
				serialize.to_lua(v, depth + 1)
			)
		end
		table.insert(strings, "\n" .. indent(depth) .. "}")
		return table.concat(strings)
	end
	if tp == "string" then
		return "\"" .. escape(obj) .. "\""
	end
	return tostring(obj)
end

return serialize
