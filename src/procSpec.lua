-- Code generator
-- (c) Reuben Thomas 2001

-- Take the specifications and generate:
--   * The opcode enumeration [opEnum.h]
--   * The name -> opcode map [insts.gperf]


-- Global formatting parameters
width = 72 -- max width of output files
indent = 2 -- indent of data structures

-- write a string wrapped with the above parameters, with a
-- terminating newline
function writeWrapped(s)
  writeLine(wrap(s, width, indent, indent))
end


-- list of instruction names in opcode order
name = project(inst, "name")

-- instEnum.h
-- enumeration of opcodes
-- each instruction name is uppercased and prefixed with "OP_"
writeto("instEnum.h")
writeLine("/* Instruction opcodes */\n",
          "#ifndef MITE_INSTENUM",
          "#define MITE_INSTENUM\n\n",
          "typedef enum {")
instEnum = map(opify, name)
instEnum[1] = instEnum[1] .. " = 0x01"
writeWrapped(join(", ", instEnum))
writeLine("} Opcode;\n",
          "#endif")

-- insts.gperf
-- list of name, opcode pairs in alphabetical order
writeto("insts.gperf")
writeLine("%{",
          "#include \"insts.h\"",
          "%}",
          "struct Inst { const char *name; Opcode opcode; };",
          "%%")
for i = 1, getn(inst) do
  writeLine(name[i] .. ", " .. opify(name[i]))
end
