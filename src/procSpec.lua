-- Generate code & data tables from Mite specification
-- (c) Reuben Thomas 2001

-- Take the specifications and generate:
--   * The opcode enumeration [instEnum.h]
--   * The name -> opcode map [insts.gperf]


-- instEnum.h
-- enumeration of opcodes
-- each instruction name is uppercased and prefixed with "OP_"
io.output ("instEnum.h")
io.writelines ("/* Instruction opcodes */\n",
               "#ifndef MITE_INSTENUM",
               "#define MITE_INSTENUM\n\n",
               "typedef enum {")
instEnum = std.functional.map (opify, std.ielems, std.table.project ("name", inst))
writeWrapped (table.concat (instEnum, ", "))
io.writelines ("} Opcode;\n",
               "#endif")

-- insts.gperf
-- list of name, opcode pairs in alphabetical order
io.output ("insts.gperf")
io.writelines ("%{",
               "#include \"insts.h\"",
               "%}",
               "struct Inst { const char *name; Opcode opcode; };",
               "%%")
for i = 1, #inst do
  io.writelines (inst[i].name .. ", " .. opify (inst[i].name))
end
