require "io"
require "os"
require "scbs/lib"

local proj = scbs.project {}
proj.toolchains = {"llvm", "gcc"}

scbs.VERBOSITY = 4

local lj_dir = "/s/Projects/luarjit2/";

local act_luajit = scbs.action (
	function(self, proj)
		proj.data.luajit_libname = scbs.lib.find(lj_dir .. "src", "libluarjit");
	end
)

local tgt_main = {
	output_name = "scbs",
	languages = {"c++20"},
	sources = {
		"source/luascbs/main.cpp"
	},
	incpaths = {
		"include",
		lj_dir .. "src"
	},
	linklibs = {},
	libpaths = {lj_dir .. "src"},
	deps = {
		act_luajit,
		scbs.action (
			function(self, proj)
				local libname = proj.data.luajit_libname;
				proj.targets.main.linklibs = {":" .. libname};
			end
		)
	}
};

proj.targets = {
	main = tgt_main
}

return proj
