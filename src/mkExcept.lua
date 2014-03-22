-- Generate exception headers from the exception table
-- (c) Reuben Thomas 2001

-- Take the exception table and generate:
--   * The exception enumeration [excEnum.h]
--   * List of exception messages [excMsg.h]

Exc = Object {_init = {
    "name",
    "message",
}}

dofile (arg[1]) -- load the exceptions table


-- excEnum.h
-- enumeration of opcodes
function prefix (s)
  return "Exc" .. s
end
io.output ("excEnum.h")
excEnum = list.map (prefix, list.project ("name", exception))
excEnum[1] = excEnum[1] .. " = 0x01"
writeWrapped (table.concat (excEnum, ", "))

-- excMsg.h
-- list of messages
function quote (s)
  return "\"" .. s .. "\""
end
io.output ("excMsg.h")
io.writelines (table.concat (list.map (quote, list.project ("message", exception)), ",\n"))
