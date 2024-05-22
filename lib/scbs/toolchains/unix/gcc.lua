--[[
GNU compiler collection toolchain (gcc, g++, gnu-binutils, GAS, ld, ...)
so, either GCC at *nix system or MinGW
]]

require "io"
require "os"

local unixtc = require "scbs/toolchains/unix/common"
local gcc = {}
local debugprint = debugprint or print

function gcc.check(conf) return unixtc.check(conf, "gcc") end
function gcc.init_cache(obj) return unixtc.init_cache(obj, "gcc") end
function gcc.to_asm(target, code, output) return unixtc.to_asm(target, code, output, "gcc") end
function gcc.to_obj(target, code, output) return unixtc.to_obj(target, code, output, "gcc") end
function gcc.to_bin(target, code, output) return unixtc.to_bin(target, code, output, "gcc") end
function gcc.build(proj, target) return unixtc.build(proj, target, "gcc") end

return gcc
