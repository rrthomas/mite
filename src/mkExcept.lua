-- Generate exception headers from the exception table
-- (c) Reuben Thomas 2001

-- Take the exception table and generate:
--   * The exception enumeration [excEnum.h]
--   * List of exception messages [excMsg.h]

Exc = Object{_init = {
    "name",
    "message", -- printed when throw reaches the top level
}}

dofile(arg[1]) -- load the exceptions table


-- excEnum.h
-- enumeration of opcodes
function prefix(s)
  return "Exc" .. s
end
writeto("excEnum.h")
excEnum = map(prefix, project("name", exception))
excEnum[1] = excEnum[1] .. " = 0x01"
writeWrapped(join(", ", excEnum))

-- excMsg.h
-- list of messages
function quote(s)
  return "\"" .. s .. "\""
end
writeto("excMsg.h")
writeLine(join(",\n", map(quote, project("message", exception))))
