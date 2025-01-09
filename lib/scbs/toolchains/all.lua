--[[

Created 30 Mar 2024 at 22:13:10 or earlier
by reglnk

]]

local gcc = require "scbs/toolchains/unix/gcc"
local llvm = require "scbs/toolchains/unix/llvm"

return {
    gcc = gcc,
	llvm = llvm
}
