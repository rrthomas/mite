-- Mite instruction table generator
-- (c) Reuben Thomas 2001

-- Take the raw instruction table and generate:
--   1. The opcode enumeration [opEnum.h]
--   3. The array of names indexed by opcode [opToName.h]
--   2. The name -> opcode map [insts.gperf]
--   4. The documentation tables [instLab.tex, instComp.tex,
--      instData.tex, instOpcode.tex]

-- See insts.lua for the format of the instruction table


dofile("util.lua")
dofile("insts.lua")
nameToInst = makeIndex("name", inst)

-- Global formatting parameters
width = 72 -- max width of output files
indent = 2 -- indent of data structures

-- Expand the desc fields of the instructions
for i = 1, getn(inst) do
  local d = inst[i].desc
  d = gsub(d, "%%(%d)",
           function (n)
             return tostring(inst[%i].ops[tonumber(n)]) .. "_" ..
               tostring(n)
           end)
  d = gsub(d, "%%%%", "%%")
  d = gsub(d, "%<%-", "\\gets ")
  inst[i].desc = d
end

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


-- LaTeX fragments
-- write LaTeX table lines for the given instructions
function writeTable(...)
  for i = 1, arg.n do
    local inst = inst[nameToInst[arg[i]]]
    write(inst.name .. " ")
    for j = 1, getn(inst.ops) do
      write("$" .. inst.ops[j] .. "_" .. tostring(j) .. "$ ")
    end
    write("& " .. inst.desc .. " \\\\\n")
  end
end

-- instLab.tex: the label instruction
writeto("instLab.tex")
writeTable("lab")

-- instComp.tex: the computational instructions
writeto("instComp.tex")
writeTable("mov", "movi", "ldl", "ld", "st", "gets", "sets", "pop",
           "push", "add", "sub", "mul", "div", "rem", "and", "or",
           "xor", "sl", "srl", "sra", "teq", "tlt", "tltu", "b", "br",
           "bf", "bt", "call", "callr", "ret", "calln")

-- instData.tex: the data instructions
writeto("instData.tex")
writeTable("lit", "litl", "space")

-- instOp.tex: the opcode table (3 columns)
function opEntry(n)
  if inst[n] == nil then return "" end
  return inst[n].name .. " & " .. format("%0.2x", n) .. "h"
end

writeto("instOpcode.tex")
rows = ceil(getn(inst) / 3)
for i = 1, rows do
  write(opEntry(i) .. " & " .. opEntry(i + rows) .. " & " ..
        opEntry(i + rows * 2) .. " \\\\\n")
end
