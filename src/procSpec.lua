-- Generate code & data tables from Mite specification
-- (c) Reuben Thomas 2001

-- Take the specifications and generate:
--   * The opcode enumeration [instEnum.h]
--   * The name -> opcode map [insts.gperf]


-- instEnum.h
-- enumeration of opcodes
-- each instruction name is uppercased and prefixed with "OP_"
writeto("instEnum.h")
writeLine("/* Instruction opcodes */\n",
          "#ifndef MITE_INSTENUM",
          "#define MITE_INSTENUM\n\n",
          "typedef enum {")
instEnum = map(opify, project(inst, "name"))
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
  writeLine(inst[i].name .. ", " .. opify(inst[i].name))
end
