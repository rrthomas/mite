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

OpType = function(decls, code)
  -- decls: declarations for the operand reading code
  -- code: code to read an operand of the given type
  -- either a string, or a function (inst, op_no) -> string in both
  -- decls and code, the name of the operand is substituted for %o
           function funcify(f)
             if type(f) ~= "function" then
               return function (inst, op)
                        return %f
                      end
             end
             return f
           end
           local t = {decls = funcify(decls), code = funcify(code)}
           return t
         end

Translator = constructor{
  "decls",         -- extra variable declarations
  "init",          -- extra initialisation
  "update",        -- update after reading each instruction
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
-- Need to implement set type to make the next line work
--affirm(set(project(opType, name)) ==
--         set(project(listify(r.opType), 1)),
--         "operand type " .. tostring(i) .. " ('" ..
--           r.opType[i].name .. "') should be '" .. opType[i].name ..
--           "'") 

-- Check the writer implements the correct instructions
for i = 1, getn(inst) do
  affirm(w.inst[i].name == inst[i].name,
         "instruction " .. tostring(i) .. " ('" .. w.inst[i].name ..
           "') should be '" .. inst[i].name .. "'")
end


-- Write the C file

writeto(transFunc .. ".c") -- open the output file
writeLine("/* " .. r.reads .. " to " .. w.writes .. " translator */\n")
writeLine("#include \"translators.h\"")

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
          "  LabelType ty;",
          "  Opcode o;",
          "  " .. r.trans.decls,
          "  for (ty = 0; ty < LABEL_TYPES; ty++)",
          "    t->labels[ty] = 0;",
          "  " .. r.trans.init,
          "  while (t->rPtr < t->rEnd) {",
          "    o = rdInst(t);",
          "    " .. r.trans.update,
          "    ensure(" .. r.trans.maxInstLen .. ");",
          "    switch (o) {")

-- The instruction cases
for i = 1, getn(inst) do
  function substOp(s, op)
    return gsub(s, "%%o", op)
  end
  writeLine("    case " .. opify(inst[i].name) .. ":",
            "      {")
  local inst = inst[i]
  for j = 1, getn(inst.ops) do
    local opType = inst.ops[j]
    local opTypeInfo = r.opType[opType]
    local decls = opTypeInfo.decls(inst, j)
    local code = opTypeInfo.code(inst, j)
    local opVar = opType .. tostring(j)
    if decls ~= "" then
      writeLine("        " .. substOp(decls, opVar))
    end
    if code ~= "" then
      writeLine("        " .. substOp(code, opVar))
    end
  end
  writeLine("        " .. w.inst[i].def .. ";",
            "        break;",
            "      }")
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
