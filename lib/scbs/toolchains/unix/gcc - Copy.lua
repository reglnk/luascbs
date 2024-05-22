--[[
GNU compiler collection toolchain (gcc, g++, gnu-binutils, GAS, ld, ...)

requirements to toolchains
1. compiler (c, c++ --> assembly or object code)
2. assembler (asm --> object code)
3. linker (object code --> binary)

that boils down to {
	to_asm = function(ctx, code, output) ...
	to_obj = function(ctx, code, output) ...
	to_bin = function(ctx, code, output) ...
}
--]]

require "io"
require "os"
local scbs = require "scbs/common"
local base = require "scbs/base"

local gcc = {}
local debugprint = debugprint or print

local CU_cpp = {
	cpp = true,
	cxx = true,
	cc = true
}

function gcc.init_cache(obj)
	if not obj.cache then
		obj.cache = {}
	end
	if not obj.cache.gcc then
		obj.cache.gcc = {}
	end
	return obj.cache.gcc
end

local function check_c(target)
	local cache = target.cache.gcc
	if not cache.c_ver then
		cache.c_ver = false
		for k, v in pairs(target.languages) do
			if v:find("c") and not v:find("c++") then
				cache.c_ver = v
				break
			end
		end
	end
	return cache.c_ver
end

local function check_cxx(target)
	local cache = target.cache.gcc
	if not cache.cxx_ver then
		cache.cxx_ver = false
		for k, v in pairs(target.languages) do
			if v:find("c++") then
				cache.cxx_ver = v
				break
			end
		end
	end
	return cache.cxx_ver
end

function gcc.to_asm(target, code, output)
	local ext = scbs.getext(code)
	if not ext then
		print("failed to get extension from " .. code)
		return 1
	end

	local cache = gcc.init_cache(target)
	check_c(target)
	check_cxx(target)

	local prog
	if cache.cxx_ver and CU_cpp[ext] then
		prog = "g++"
	elseif cache.c_ver and ext == "c" then
		prog = "gcc"
	else
		print("wrong extension: " .. ext)
		return 1
	end

	-- @todo return command instead of executing it
	-- @todo first make shell script out of project
	local cmd = prog .. ' ' .. code .. " -S -o " .. output;
	local res = os.execute(cmd);

	if res ~= 0 then
		print("command failed: " .. cmd .. "\nreturn code: " .. res)
	end
	return 0
end

function gcc.to_obj(target, code, output)
	local ext = scbs.getext(code)
	if not ext then
		print("failed to get extension from " .. code)
		return 1
	end

	local cache = gcc.init_cache(target)
	check_c(target)
	check_cxx(target)

	local handle;
	if ext == ".s" or ext == ".asm"
	then
		-- if the assembly was compiled from C++ code, it should be later linked with C++ libraries
		-- GCC usually puts the line of look `.file "code.cpp"` or `.file "code.c"` so detect extension from here
		handle = io.open(code)
		if not handle then
			print("failed to open file " .. code)
			return 1
		end

		local line
		repeat
			line = handle:read("*l")
			if line.find(".file") then
				break
			end
		until line == "";

		if line == "" then
			debugprint("assuming C-compatible assembly: " .. code)
			ext = "c"
		else
			local badfmt = "bad assembly format: " .. code

			local b = line.find('"')
			if not b then
				print(badfmt)
				return 1
			end
			local e = line.find('"', b + 1)
			if not e then
				print(badfmt)
				return 1
			end

			local filename = string.sub(line, b, e)
			ext = scbs.getext(filename)
			debugprint("got extension from .file: " .. ext)
		end
	end

	local prog, std;
	if cache.c_ver and ext == "c" then
		prog, std = "gcc", cache.c_ver;
	elseif cache.cxx_ver and CU_cpp[ext] then
		prog, std = "g++", cache.cxx_ver;
	else
		print("wrong extension: " .. ext)
		return 1
	end

	local cmd = table {prog, "-c", "-o", "\"" .. output .. "\"", "-std=" .. std}
	if target.bintype == base.binType.shared then
		cmd:insert("-fPIC");
	end
	cmd:insert(code);
	for k, v in pairs(target.incpaths) do
		table.insert(cmd, "-I\"" .. v .. "\"")
	end
	cmd = table.concat(cmd, ' ')
	debugprint("executing: " .. cmd);
	local res = os.execute(cmd);
	if res ~= 0 then
		print("command failed: " .. cmd .. "\nreturn code: " .. res)
	end
	return 0
end

-- add some features like 'make DLL, executable, static library...'
function gcc.to_bin(target, code, output)
	local cache = gcc.init_cache(target)
	check_c(target)
	check_cxx(target)

	local is_cxx = false
	for i, v in ipairs(code) do
		local ext, base = scbs.getext(v, true)
		if not (base and #base ~= 0) then
			print("failed to get extension from " .. v)
			return 1
		end
		if not (ext == "o" or ext == "obj") then
			debugprint("warning: wrong extension: '" .. v .. "'")
		end
		local ext = scbs.getext(base)
		if not ext then
			print("failed to get extension from " .. base)
			return 1
		end
		if CU_cpp[ext] then
			is_cxx = true
		elseif ext ~= "c" then
			debugprint("wrong extension: '" .. base .. "'")
			return 1
		end
	end

	if (not cache.c_ver) and not is_cxx then
		print("C objects are not allowed")
		return 1
	elseif (not cache.cxx_ver) and is_cxx then
		print("C++ objects are not allowed")
		return 1
	end

	local prog; if not is_cxx
	then prog = "gcc"
	else prog = "g++" end

	local res, cmd;
	target.bintype = target.bintype or base.binType.app;
	
	if target.bintype == base.binType.app
	then
		if SOURCE_OS == "win32" then
			output = output .. ".exe"
		end
		cmd = table {prog, "-o", "\"" .. output .. "\""};
	elseif target.bintype == base.binType.shared
	then
		cmd = table {prog, "-o", "\"" .. output .. "\"", "-shared"};
	elseif target.bintype == base.binType.static
	then
		error("static libs are not yet supported");
	else
		error("unknown target binary type: " .. tostring(target.bintype));
	end
	table.move(code, 1, #code, #cmd + 1, cmd);
	for i, v in ipairs(target.linklibs or {}) do
		table.insert(cmd, "-l" .. v)
	end
	for i, v in ipairs(target.libpaths or {}) do
		table.insert(cmd, "-L\"" .. v .. "\"")
	end
	
	cmd = table.concat(cmd, " ")
	debugprint("executing: " .. cmd)
	res = os.execute(cmd)
	if res ~= 0 then
		if debugprint ~= print then
			print("command failed: " .. cmd .. "\nexit code: " .. res)
		else
			print("exit code: " .. res)
		end
	end
	return 0
end

-- todo: add feature for private includes for each source file
-- also necessary for cmake compat
function gcc.build(proj, target)
	local cache = gcc.init_cache(proj)
	cache.built = cache.built or {}
	if cache.built[target] then
		debugprint("already built: " .. target)
		return 0
	end
	
	local objects = {}
	for k, v in pairs(target.sources) do
		local objname = v .. ".o"
		if gcc.to_obj(target, v, objname) ~= 0 then
			return 1
		end
		table.insert(objects, objname)
	end
	local res = gcc.to_bin(target, objects, "prog")
	if res ~= 0 then
		return res
	end
	cache.built[target] = true
	return 0
end 

return gcc
