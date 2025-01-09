-- Added 27 Aug 2024 or earlier
-- by reglnk

require "scbs/fs";

scbs = scbs or {}
scbs.lib = {}
local lib = scbs.lib;
local fs = scbs.fs;

lib.any = {shared = 1, static = 1}

-- This is only for MinGW and Unix toolchains so far
-- @todo macos

-- whether this file may be used for linking with shared library
-- in *nix this is the .so itself
-- in MinGW this is .dll.a
function lib.isSharedLink(filename, ctx)
	ctx = ctx or scbs;
	if ctx.OS ~= "win32" then
		return filename:sub(-3, -1) == ".so"
	end
	return filename:sub(-6, -1) == ".dll.a"
end

function lib.isShared(filename, ctx)
	ctx = ctx or scbs;
	if ctx.OS ~= "win32" then
		return file:sub(-3, -1) == ".so"
	end
	return file:sub(-4, -1) == ".dll"
end

function lib.isStaticLink(filename)
	return filename:sub(-2, -1) == ".a"
end

-- `types` is a table
-- if types.shared then the shared lib is suitable
-- if types.static then the static is suitable
-- if some of them is more preferred, assign them different integer values, like this
-- {shared = 2, static = 1}
-- by default, the shared one is preferred.
-- if name has regexes, the behaviour is undefined.
-- @todo lib.findraw which finds both
function lib.find(path, name, types, required, versions)
--[
	types = types or lib.any;
	types = type(types) == "table" and types or {types}
	required = required ~= nil and required or true;
	local shared, static;
	local filter = function(file)
		local ok = false;
		if not file:find(name) then
			scbs:debugprint("filename `".. file .."' doesn't match `".. name .."'");
			return false
		end
		if types.shared and lib.isSharedLink(file) then
			shared = file;
			scbs:vprint("found shared library ".. file .." at `".. path .."'");
			return true
		end
		if types.static and lib.isStaticLink(file) then
			static = file;
			scbs:vprint("found static library ".. file .." at `".. path .."'");
			return true
		end
		return false
	end
	scbs:debugprint("searching for library `".. name .."' at `".. path .."'");
	local fil = fs.find(path, filter);
	assert(#fil <= 2);
	print(shared, static)
	assert(shared ~= static); -- keep in mind: not {nil, nil}, nor {"libsmth.so", "libsmth.so"}
	scbs:debugprint("found ".. #fil .." libs at `".. path .."'");
	local sel;
	if not types.static then sel = shared
	elseif not types.shared then sel = static
	elseif #fil == 1 then sel = static or shared
	else sel = (types.static > types.shared) and static or shared
	end
	if sel == shared then
		scbs:vprint("selected shared library `".. sel .."'");
	elseif (sel == static) then
		scbs:vprint("selected static library `".. sel .."'");
	else
		assert(not sel);
		if required then
			scbs:error("library `".. name .."' is not found at path: `".. path .."'");
		end
	end
	return sel;
end
