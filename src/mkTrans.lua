-- Mite translator generator
-- (c) Reuben Thomas 2001

-- Generate a C translator from a reader and a writer specification

readerFile, writerFile, transFunc = arg[1], arg[2], arg[3]


-- Global formatting parameter
instWidth = 36

-- Constructors
Reader = constructor{
  "reads",       -- what is read
  "prelude",     -- literal source code
  "rdInst",      -- code to read an instruction
  "labelAddr",   -- map a label's name to its address
  "opType",      -- operand type reader table
  "trans",       -- reader-specific parts of translator function  
}

OpType = constructor{
  "name",  -- operand type name
  "cType", -- C representation type
  "def",   -- definition
}

Translator = constructor{
  "decls",         -- extra variable declarations
  "init",          -- extra initialisation
  "updateExcLine", -- code to increment excLine
  "maxInstLen",    -- max. no. of bytes required by next instruction
}

Writer = constructor{
  "writes",       -- what is written
  "prelude",      -- literal source code
  "dangleMaxLen", -- DANGLE_MAXLEN
  "resolveImg",   -- RESOLVE_IMG
  "resolvePtr",   -- RESOLVE_PTR
  "inst",         -- instruction table
}

Inst = constructor{
  "name", -- instruction name
  "def",  -- definition
}

-- Construct the operand list of an instruction writer macro
function ops(inst)
  local s, n = "(", getn(inst.ops)
  for i = 1, n do
    local o
    if inst.ops[i] == "i" then
      o = "f, n, v, r"
    else
      o = inst.ops[i] .. tostring(i)
    end
    s = s .. o
    if i < n then
      s = s .. ", "
    end
  end
  return s .. ")"
end


-- Load the reader and writer

r, w = dofile(readerFile), dofile(writerFile)

-- Check the reader implements the correct opTypes
for i = 1, getn(opType) do
  affirm(r.opType[i].name == opType[i].name,
         "operand type " .. tostring(i) .. " ('" .. r.opType[i].name ..
           "') should be '" .. opType[i].name .. "'")
end

-- Check the writer implements the correct instructions
for i = 1, getn(inst) do
  affirm(w.inst[i].name == inst[i].name,
         "instruction " .. tostring(i) .. " ('" .. w.inst[i].name ..
           "') should be '" .. inst[i].name .. "'")
end


-- Write the C file

writeto(transFunc .. ".c") -- open the output file
writeLine("/* " .. r.reads .. " to " .. w.writes .. " translator */\n")

-- Reader prelude and macros
writeLine(r.prelude,
          "#define rdInst(t) " .. r.rdInst,
          "#define labelAddr(t, l) " .. r.labelAddr .. "\n")

-- Writer prelude and macros
writeLine(w.prelude,
          "#define DANGLE_MAXLEN " .. w.dangleMaxLen,
          "#define RESOLVE_IMG " .. w.resolveImg,
          "#define RESOLVE_PTR " .. w.resolvePtr .. "\n")

-- Start of the translator function
writeLine("TState *",
          transFunc .. "(Byte *rImg, Byte *rEnd)",
          "{",
          "  TState *t = translatorNew(rImg, rEnd);",
          "  LabelType l;",
          "  Opcode o;",
          r.trans.decls,
          "  for (l = 0; l < LABEL_TYPES; l++)",
          "    t->labels[l] = 0;",
          r.trans.init,
          "  while (t->rPtr < t->rEnd) {",
          "    o = rdInst(t)",
          r.trans.updateExcLine,
          "    ensure(" .. r.trans.maxInstLen .. ");",
          "    switch (o) {")

-- The instruction cases
for i = 1, getn(inst) do
  writeLine("    case " .. opify(inst[i].name) .. ":",
            "      {")
  local inst = inst[i]
  for j = 1, getn(inst.ops) do
    local opType = inst.ops[j]
    local opTypeInfo = r.opType[opType]
    write("      ")
    if opTypeInfo.cType ~= "" then
      write(opTypeInfo.cType .. " " .. opType ..
            tostring(j) .. " = ")
    end
    writeLine(opTypeInfo.def .. ";")
  end
  writeLine("      " .. w.inst[i].def .. ";",
            "      break;")
end
writeLine("    default:",
          "      throw(\"bad instruction\");")

-- End of the translator function
writeLine("    }",
          "  }",
          "  excLine = 0;",
          "  resolve(t);",
          "  return t;",
          "}")
