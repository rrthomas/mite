-- Generate documentation tables from specification
-- (c) Reuben Thomas 2001, 2014


-- Make a name->instruction index
-- FIXME: Get index_value from rrtlib
nameToInst = std.list.index_value ("name", inst)

-- Expand the effect fields of the instructions
for i = 1, #inst do
  local d = inst[i].effect
  d = string.gsub (d, "%%(%d)",
                   function (n)
                     return tostring (inst[i].ops[tonumber (n)]) .. "_" ..
                       tostring (n)
  end)
  d = string.gsub (d, "%%%%", "%%")
  d = string.gsub (d, "%<%-", "\\gets ")
  inst[i].effect = d
end

-- write LaTeX table lines for the given instructions
function writeTable (...)
  local arg = {...}
  for i = 1, #arg do
    local inst = nameToInst[arg[i]]
    io.write (inst.name .. " ")
    for j = 1, #inst.ops do
      io.write ("$" .. inst.ops[j] .. "_" .. tostring (j) .. "$ ")
    end
    io.write ("& " .. inst.effect .. " \\\\\n")
  end
end

-- instLab.tex: the label instruction
io.output ("instLab.tex")
writeTable ("lab")

-- instComp.tex: the computational instructions
io.output ("instComp.tex")
writeTable ("mov", "movi", "ldl", "ld", "st", "ldo", "sto", "add",
            "sub", "mul", "div", "rem", "and", "or", "xor", "sl",
            "srl", "sra", "teq", "tlt", "tltu", "b", "br", "bf", "bt",
            "call", "callr", "ret", "salloc")

-- instData.tex: the data instructions
io.output ("instData.tex")
writeTable ("lit", "litl", "space")

-- instCcall.tex: the C call instructions
io.output ("instCcall.tex")
writeTable ("func", "funcv", "arg", "callf", "callfr", "retf", "retf0")

-- instOp.tex: the opcode table (3 columns)
function opEntry (n)
  if inst[n] == nil then return "" end
  return inst[n].name .. " & " .. string.format ("%0.2x", n) .. "h"
end

io.output ("instOpcode.tex")
rows = math.ceil (#inst / 3)
for i = 1, rows do
  io.writelines (opEntry (i) .. " & " .. opEntry (i + rows) .. " & " ..
                   opEntry (i + rows * 2) .. " \\\\")
end

-- opTypes.tex: the operand types
io.output ("opTypes.tex")
for i = 1, #opType do
  io.writelines (opType[i].name .. " & " .. opType[i].desc .. " \\\\")
end
