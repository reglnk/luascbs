require "io"
require "os"
local ffi = require "ffi"
local lfs = require "lfs"
local fsutil = require "scbs/fsutil"

local proj = project {}

--[[ proj.toolchains = {
	llvm = "14.0",
	gcc = "11.1",
	msvc = {{"v141", "v143"}}
} --]]

--[[ or

proj.toolchains = {
	llvm = {
		versions = {
			["clang"] = "17.0",
			["clang++"] = "17.0",
			["ld.lld"] = "17.0.4"
		}
	},
	gcc = {
		versions = {
			["gcc"] = "11.1",
			["g++"] = "12.1",
			["ld"] = "2.38"
		}
	},
	msvc = {{"v141", "v143"}}
}

--]]

local lj_dir = "ext/LuaJIT-2.1/";

local act_luajit = action {
	fn = function(self, proj)
		local files = fsutil.find(lj_dir.."src", "libluajit");
		assert(#files == 1);
		proj.data.luajit_libname = files[1]
	end,
}

local tgt_main = table {
	languages = table {"c++20"},
	sources = table {
		"source/luascbs/main.cpp"
	},
	incpaths = table {
		"include",
		lj_dir .. "src"
	},
	linklibs = table {},
	libpaths = table {lj_dir .. "src"},
	deps = table {
		act_luajit,
		action {
			fn = function(self, proj)
				local libname = proj.data.luajit_libname;
				proj.targets.main.linklibs = table {":" .. libname};
			end
		}
	}
};

proj.targets = {
	main = tgt_main
}

return proj
