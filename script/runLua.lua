-- Wrapper for Lua scripts
-- (c) Reuben Thomas 2001

miteDir, script = arg[1], arg[2] -- $(MITE), name of script
prog = { name = gsub (arg[2], "%..*$", "") }
require "std.lua" -- standard library
shift (2) -- remove the arguments
dofile (miteDir .. "/script/miteUtil.lua") -- Mite-specific utilities
dofile (miteDir .. "/spec.lua") -- Mite's specification
dofile (script) -- run the given script
