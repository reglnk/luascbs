-- target languages: c, c++, asm

local tc_all = require "scbs/toolchains/all"
local tc_check = require "scbs/toolchains/check"
local serialize = require "scbs/serialize"

require "io"
require "scbs/util"
local scbs = require "scbs/common"
local base = require "scbs/base"
scbs.globalize(base);

local function save_config(conf, dir)
	dir = dir or ".";
	local fd = io.open(dir .. "/scbsconf.lua", "w")
	if not fd then return false end
	local code = serialize.to_lua(conf)
	fd:write("return ", code, "\n")
	fd:close()
	return true
end

local function load_config(dir)
	dir = dir or ".";
	local fd = io.open(dir .. "/scbsconf.lua", "r")
	if not fd then return nil end
	return dofile(dir .. "/scbsconf.lua")
end

local function generate_config(proj, toolchain_id)
	proj.conf = proj.conf or {}
	local conf = proj.conf
	conf.
	if toolchain_id then
		if not proj.toolchains[toolchain_id] then
			print("warning: the project does not support " .. toolchain_id)
		end
		
		local versions = tc_check(proj, id);
		if not versions then
			error("toolchain " .. id .. " is missing or incomplete")
		end
		-- todo: check versions for compatibility
		conf.toolchain = id
		conf.versions = versions
	else
		local sel = proj.toolchains
		if (not sel) or #sel == 0 then
			sel = tc_all
		end
		for k, v in pairs(sel) do
			print('checking ', k);
			local versions = tc_check(proj, k)
			if versions then
				-- todo: check versions for compatibility
				conf.toolchain = k
				conf.versions = versions
				break
			end
		end
		if not conf.toolchain then
			error("no suitable toolchains found")
		end
	end
	return conf
end

local actionType = {
	config = {},
	build = {},
	export = {}
}

local function parse_args(args)
	local needs_arg = function(key)
		; -- @stopped here
	end
	local opt = {}
	for i, v in ipairs(args) do
		if v.at(1) == "-" then
	end
end

local function runconfig(proj, args)
	local conf = load_config()
	if not conf then
		conf = generate_config(proj, nil)
		assert(save_config(conf))
	end
end

local function runbuild(prog, args)
	local conf = load_config()
	if not conf then
		conf = generate_config(proj, nil)
		assert(save_config(conf))
	end
	proj.conf = conf;
	proj.toolchain = tc_all[conf.toolchain];
	proj.data = table {} -- user-defined data
	-- proj.toolchains.custom.build(proj)
	for k, v in pairs(proj.targets) do
		proj:resolve_deps(v.deps);
		local res = proj.toolchain.build(proj, v)
		if res ~= 0 then
			print("failed to build target: " .. k)
			return 1
		end
	end
end

local scenarios = {
	[actionType.config] = runconfig,
	[actionType.build] = runbuild
};

function scbsmain(proj, args)
	local action_sel = {
		config = actionType.config,
		c = actionType.config,
		build = actionType.build,
		b = actionType.build
	}
	local action = actionType.config
	if #args ~= 0 then
		action = action_sel[args[1]]
	end
	if not action then print (
		"Usage: scbs [config | build | export] [options...]\n" ..
		"Default action is config."-- Call a subcommand with --help for more info"
	);
	return 1 end
	return scenarios[action](args:sub(2));
end
