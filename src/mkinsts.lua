-- Mite instruction table generator
-- (c) Reuben Thomas 2001

-- Take the raw instruction table and generate:
--   1. The opcode enumeration [opEnum.h]
--   3. The array of names indexed by opcode [opToName.h]
--   2. The name -> opcode map [insts.gperf]

-- See $(MITE)/spec/insts.lua for the format of the instruction table


miteDir = arg[1] -- $(MITE)
dofile(miteDir .. "/script/util.lua") -- utility routines
dofile(miteDir .. "/spec/insts.lua") -- instruction set spec

-- Global formatting parameters
width = 72 -- max width of output files
indent = 2 -- indent of data structures

-- produce OP_NAME from name
function opify(n)
  return "OP_" .. strupper(n)
end

-- opEnum.h
-- enumeration of opcodes
-- each instruction name is uppercased and prefixed with OP_
writeto("opEnum.h")
write("/* Instruction opcodes */\n\n")
write("#ifndef MITE_OPENUM\n")
write("#define MITE_OPENUM\n\n\n")
write("enum {\n")
s = opify(inst[1].name) .. " = 0x01, "
for i = 2, getn(inst) do
  s = s .. opify(inst[i].name) .. ", "
end
s = s .. opify("INSTS", getn(inst))
write(wrap(s, width, indent, indent) .. "\n")
write("};\n\n")
write("#endif\n")

-- opToName.h
-- char * array of instruction names in opcode order
writeto("opToName.h")
s = "\"\", " -- blank entry for 0; opcodes start at 0x01
for i = 1, getn(inst) do
  s = s .. "\"" .. inst[i].name .. "\", "
end
write(wrap(s, width, indent, indent) .. "\n")

-- insts.gperf
-- list of opcode, name pairs in alphabetical order
writeto("insts.gperf")
write("%{\n")
write("#include \"insts.h\"\n")
write("%}\n")
write("struct Inst { const char *name; unsigned int opcode; };\n")
write("%%\n")
for i = 1, getn(inst) do
  write(inst[i].name .. ", " .. opify(inst[i].name) .. "\n")
end
