-- Code generator
-- (c) Reuben Thomas 2001

-- Take the specifications and generate:
--   1. The opcode enumeration [opEnum.h]
--   2. The array of operand types indexed by opcode [opToTypes.c]
--   3. The name -> opcode map [insts.gperf]


miteDir = arg[1] -- $(MITE)
dofile(miteDir .. "/script/util.lua") -- utility routines
dofile(miteDir .. "/spec.lua") -- Mite's specification

-- Global formatting parameters
width = 72 -- max width of output files
indent = 2 -- indent of data structures

-- write a string wrapped with the above parameters, with a
-- terminating newline
function writeWrapped(s)
  write(wrap(s, width, indent, indent) .. "\n")
end

-- produce OP_NAME from name
function opify(n)
  return "OP_" .. strupper(n)
end

-- list of instruction names in opcode order
name = project(inst, "name")

-- opEnum.h
-- enumeration of opcodes
-- each instruction name is uppercased and prefixed with OP_
writeto("opEnum.h")
write("/* Instruction opcodes */\n\n")
write("#ifndef MITE_OPENUM\n")
write("#define MITE_OPENUM\n\n\n")
write("enum {\n")
s = opify(name[1]) .. " = 0x01, "
for i = 2, getn(inst) do
  s = s .. opify(name[i]) .. ", "
end
s = s .. opify("INSTS", getn(inst))
writeWrapped(s)
write("};\n\n")
write("#endif\n")

-- opToOps.h
-- unsigned int array of instruction operand types in opcode order
--
maxInstNameLen = call(max, map(strlen, name))

function ops(i)
  return "OPS(" .. (i.ops[1] or "_") .. "," .. (i.ops[2] or "_") ..
    "," .. (i.ops[3] or "_") .. ")"
end

function opsLine(i)
  return "/* " .. pad(i.name, maxInstNameLen) .. " */ " .. ops(i) ..
    ",\n"
end

writeto("opToTypes.c")
s = "0,\n" -- blank entry; opcodes start at 0x01
for i = 1, getn(inst) do
  s = s .. opsLine(inst[i])
end
write(s)

-- insts.gperf
-- list of opcode, name pairs in alphabetical order
writeto("insts.gperf")
write("%{\n")
write("#include \"insts.h\"\n")
write("%}\n")
write("struct Inst { const char *name; unsigned int opcode; };\n")
write("%%\n")
for i = 1, getn(inst) do
  write(name[i] .. ", " .. opify(name[i]) .. "\n")
end
