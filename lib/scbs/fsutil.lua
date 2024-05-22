local lfs = require "lfs"
local fsutil = {}

function fsutil.find(path, pattern)
	local res = table {}
	for file in lfs.dir(path) do
		if file:find(pattern) then
			res:insert(file);
		end
	end
	return res;
end

return fsutil
