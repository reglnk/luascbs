local lfs = require "lfs"
local fs = {}

function fs.find(path, func)
	local res = table {};
	print(path);
	for file in lfs.dir(path) do
		if func(file) then
			res:insert(file)
		end
	end
	return res
end

scbs = scbs or {}
scbs.fs = fs;

return fs
