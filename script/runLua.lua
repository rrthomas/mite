-- Wrapper for Lua scripts
-- (c) Reuben Thomas 2001

miteDir, script = arg[1], arg[2] -- $(MITE), name of script
prog = { name = string.gsub (arg[2], "%..*$", "") }
std = require "std".barrel ()
rrt_list = require "rrt.list"
Object = std.object
table.remove (arg, 1) -- remove the arguments
table.remove (arg, 1)
dofile (miteDir .. "/script/miteUtil.lua") -- Mite-specific utilities
dofile (miteDir .. "/spec.lua") -- Mite's specification
dofile (script) -- run the given script
