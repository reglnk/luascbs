--[[
Created 30 Mar 2024 at 22:14:54 or earlier
by reglnk

LLVM on *nix or LLVM-mingw on Windows (clang, clang++, lld...)
Not to be confused with LLVM for Windows, with clang-cl replacing MSVC
(that thing would be called llvm_win)
]]

require "io"
require "os"

local unixtc = require "scbs/toolchains/unix/common"
local llvm = {}
local debugprint = debugprint or print

function llvm.check(conf) return unixtc.check(conf, "llvm") end
function llvm.init_cache(obj) return unixtc.init_cache(obj, "llvm") end
function llvm.to_asm(target, code, output) return unixtc.to_asm(target, code, output, "llvm") end
function llvm.to_obj(target, code, output) return unixtc.to_obj(target, code, output, "llvm") end
function llvm.to_bin(target, code, output) return unixtc.to_bin(target, code, output, "llvm") end
function llvm.build(proj, target) return unixtc.build(proj, target, "llvm") end

return llvm
