-- Generate documentation tables from specification
-- (c) Reuben Thomas 2001


-- Make a name->instruction index
nameToInst = indexValue ("name", inst)

-- Expand the effect fields of the instructions
for i = 1, getn (inst) do
  local d = inst[i].effect
  d = gsub (d, "%%(%d)",
            function (n)
              return tostring (inst[%i].ops[tonumber (n)]) .. "_" ..
                tostring (n)
            end)
  d = gsub (d, "%%%%", "%%")
  d = gsub (d, "%<%-", "\\gets ")
  inst[i].effect = d
end

-- write LaTeX table lines for the given instructions
function writeTable (...)
  for i = 1, arg.n do
    local inst = nameToInst[arg[i]]
    write (inst.name .. " ")
    for j = 1, getn (inst.ops) do
      write ("$" .. inst.ops[j] .. "_" .. tostring (j) .. "$ ")
    end
    write ("& " .. inst.effect .. " \\\\\n")
  end
end

-- instLab.tex: the label instruction
writeto ("instLab.tex")
writeTable ("lab")

-- instComp.tex: the computational instructions
writeto ("instComp.tex")
writeTable ("mov", "movi", "ldl", "ld", "st", "ldo", "sto", "add",
            "sub", "mul", "div", "rem", "and", "or", "xor", "sl",
            "srl", "sra", "teq", "tlt", "tltu", "b", "br", "bf", "bt",
            "call", "callr", "ret", "salloc")

-- instData.tex: the data instructions
writeto ("instData.tex")
writeTable ("lit", "litl", "space")

-- instCcall.tex: the C call instructions
writeto ("instCcall.tex")
writeTable ("func", "funcv", "arg", "callf", "callfr", "retf", "retfv")

-- instOp.tex: the opcode table (3 columns)
function opEntry (n)
  if inst[n] == nil then return "" end
  return inst[n].name .. " & " .. format ("%0.2x", n) .. "h"
end

writeto ("instOpcode.tex")
rows = ceil (getn (inst) / 3)
for i = 1, rows do
  writeLine (opEntry (i) .. " & " .. opEntry (i + rows) .. " & " ..
             opEntry (i + rows * 2) .. " \\\\")
end

-- opTypes.tex: the operand types
writeto ("opTypes.tex")
for i = 1, getn (opType) do
  writeLine (opType[i].name .. " & " .. opType[i].desc .. " \\\\")
end
