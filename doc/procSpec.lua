-- Documentation generator
-- (c) Reuben Thomas 2001

-- Take the specifications and generate the documentation tables
-- instLab.tex, instComp.tex, instData.tex, instOpcode.tex and
-- types.tex


-- Make a name->instruction index
nameToInst = makeIndex("name", inst)

-- Global formatting parameters
width = 72 -- max width of output files

-- Expand the effect fields of the instructions
for i = 1, getn(inst) do
  local d = inst[i].effect
  d = gsub(d, "%%(%d)",
           function (n)
             return tostring(inst[%i].ops[tonumber(n)]) .. "_" ..
               tostring(n)
           end)
  d = gsub(d, "%%%%", "%%")
  d = gsub(d, "%<%-", "\\gets ")
  inst[i].effect = d
end

-- write a LaTeX table line for the given fields

-- write LaTeX table lines for the given instructions
function writeTable(...)
  for i = 1, arg.n do
    local inst = inst[nameToInst[arg[i]]]
    write(inst.name .. " ")
    for j = 1, getn(inst.ops) do
      write("$" .. inst.ops[j] .. "_" .. tostring(j) .. "$ ")
    end
    write("& " .. inst.effect .. " \\\\\n")
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
  writeLine(opEntry(i) .. " & " .. opEntry(i + rows) .. " & " ..
            opEntry(i + rows * 2) .. " \\\\")
end

-- types.tex: the operand types
writeto("types.tex")
for i = 1, getn(opType) do
  writeLine(opType[i].name .. " & " .. opType[i].desc .. " \\\\")
end
