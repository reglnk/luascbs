require "io"
require "scbs/util"
local toolchains = require "scbs/toolchains/all"

-- checks whether toolchain is present and working
return function(conf, id)
	local tc =  toolchains[id]
	if not tc then
		print("warning: unknown toolchain: " .. tostring(id))
		return false
	end
	return tc.check(conf);
end
