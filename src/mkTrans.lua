-- Mite translator generator
-- (c) Reuben Thomas 2001

-- Generate a C translator from a reader and a writer specification

readerFile, writerFile, transFunc = arg[1], arg[2], arg[3]


-- Global formatting parameter
instWidth = 36

-- Constructors
Reader = constructor{
  "reads",       -- what the reader reads
  "prelude",     -- literal source code
  "opType",      -- operand type reader table
  "trans",       -- reader-specific parts of translator function  
}

OpType = function(decls, code)
           -- decls: declarations for the operand reading code
           -- code: code to read an operand of the given type
           -- each is either a string, or a function (inst, op) ->
           -- string
           -- in the output, %n -> operand no.
           function funcify(f)
             if type(f) ~= "function" then
               f = function (inst, op)
                     return %f
                   end
             end
             return function (inst, opNo)
                      local s = %f(inst, opNo)
                      return gsub(s, "%%n", tostring(opNo))
                    end
           end
           local t = {decls = funcify(decls), code = funcify(code)}
           return t
         end

Writer = constructor{
  "writes",       -- what the writer writes
  "prelude",      -- literal source code
  "inst",         -- instruction table
  "trans",        -- writer-specific parts of translator function
}

Inst = constructor{
  "name", -- instruction name
  "def",  -- definition
}

Translator = constructor{
  "decls",        -- extra variable declarations
  "init",         -- extra initialisation
  "update",       -- update after reading each instruction
  "finish",       -- code to execute after translation and resolution
}


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
writeLine(r.prelude)

-- Writer prelude and macros
writeLine(w.prelude)

-- Dangle resolution function
writeLine("static void",
          "resolveDangles(TState *t, Byte *finalImg, Byte *finalPtr)",
          "{",
          "  Dangle *d;",
          "  uintptr_t prev = 0, extras, n,",
          "    off = finalPtr - finalImg;", 
          "  for (d = t->dangles->next, n = 0; d; d = d->next, n++);",
          "  finalImg = excRealloc(finalImg, t->wPtr - t->wImg + n *",
          "                        DANGLE_MAXLEN + off);",
          "  finalPtr = finalImg + off;",
          "  for (d = t->dangles->next; d; d = d->next) {",
          "    memcpy(finalPtr, t->wImg + prev, d->ins - prev);",
          "    finalPtr += d->ins - prev;",
          -- writeUInt must set extras
          "    writeUInt(&finalPtr, labelAddr(t, d->l).n);",
          "    prev = d->ins + extras;",
          "  }",
          "  memcpy(finalPtr, t->wImg + prev,",
          "         t->wPtr - t->wImg - prev);", 
          "  finalPtr += t->wPtr - t->wImg - prev;",
          "  free(t->wImg);",
          "  t->wImg = realloc(finalImg, finalPtr - finalImg);",
          "  t->wPtr = t->wImg + (finalPtr - finalImg);",
          "}",
          "")

-- Head of the translator function
writeLine("TState *",
          transFunc .. "(Byte *rImg, Byte *rEnd)",
          "{",
          "  TState *t = translatorNew(rImg, rEnd);",
          "  LabelType ty;",
          "  Opcode o;",
          "  /* reader declarations */",
          "  " .. r.trans.decls,
          "  /* writer declarations */",
          "  " .. w.trans.decls,
          "  for (ty = 0; ty < LABEL_TYPES; ty++)",
          "    t->labels[ty] = 0;",
          "  /* reader initialisation */",
          "  " .. r.trans.init,
          "  /* writer initialisation */",
          "  " .. w.trans.init,
          "  while (t->rPtr < t->rEnd) {",
          "    /* reader update */",
          "    " .. r.trans.update,
          "    /* writer update */",
          "    " .. w.trans.update,
          "    switch (o) {")

-- The instruction cases
for i = 1, getn(inst) do
  writeLine("    case " .. opify(inst[i].name) .. ":",
            "      {")
  local inst = inst[i]
  for j = 1, getn(inst.ops) do
    local opTypeInfo = r.opType[inst.ops[j]]
    local decls = opTypeInfo.decls(inst, j)
    if decls ~= "" then
      writeLine("        " .. decls)
    end
  end
  for j = 1, getn(inst.ops) do
    local opTypeInfo = r.opType[inst.ops[j]]
    local code = opTypeInfo.code(inst, j)
    if code ~= "" then
      writeLine("        " .. code)
    end
  end
  writeLine("        " .. w.inst[i].def .. ";",
            "        break;",
            "      }")
end
writeLine("    default:",
          "      throw(ExcBadInst);")

-- End of the translator function
writeLine("    }",
          "  }",
          "  excLine = 0;",
          "  resolveDangles(t, RESOLVE_IMG, RESOLVE_PTR);",
          "  /* reader finish */",
          "  " .. r.trans.finish,
          "  /* writer finish */",
          "   ".. w.trans.finish,
          "  return t;",
          "}")
