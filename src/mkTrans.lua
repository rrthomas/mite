-- Mite translator program generator
-- Generate a C file for a collection of translators
-- (c) Reuben Thomas 2002


transListFile, transFile = arg[1], arg[2]


-- Global formatting parameter
instWidth = 36

-- Constructors
Reader = constructor{
  "reads",   -- what the reader reads
  "input",   -- input type
  "prelude", -- literal source code
  "opType",  -- operand type reader table
  "trans",   -- reader-specific parts of translator function  
}

OpType =
  function(arg)
    local decls, code = arg[1], arg[2]
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
  "writes",  -- what the writer writes
  "output",  -- output type
  "prelude", -- literal source code
  "macros",  -- writer macros
  "inst",    -- instruction table
  "trans",   -- writer-specific parts of translator function
  "resolve", -- flag indicating whether dangles resolution is required
}

Inst = constructor{
  "name", -- instruction name
  "def",  -- definition
}

Translator = constructor{
  "decls",  -- extra variable declarations
  "init",   -- extra initialisation
  "update", -- update after reading each instruction
  "finish", -- code to execute after translation and resolution
}


function transFunc(reads, writes)
  return reads .. "To" .. strcaps(writes)
end

function mkTrans(arg)
  local reads, writes = arg[1], arg[2]

  -- Load the reader and writer
  local r = readers[reads]
  local w = writers[writes]
  local transFunc = transFunc(reads, writes)
  local resolveFunc = "resolveDangles" .. strcaps(transFunc)
  local rstate, wstate = reads .. "R_State", writes .. "W_State"
  local inputType = reads .. "R_Input"
  local outputType = writes .. "W_Output"

  -- Check the reader implements the correct opTypes
  affirm(setequal(Set(project("name", opType)),
                  Set(project(1, enpair(r.opType)))),
         "incorrect opType in " .. r.reads .. " reader")

  -- Check the writer implements the correct instructions
  for i = 1, getn(inst) do
    affirm(w.inst[i], "instruction " .. inst[i].name .. " missing")
    affirm(w.inst[i].name == inst[i].name,
           "instruction " .. tostring(i) .. " ('" .. w.inst[i].name ..
             "') should be '" .. inst[i].name .. "'")
  end


  -- Compose the output
  local out = "\n\n/* " .. r.reads .. " to " .. w.writes ..
    " translator */\n\n"

  -- Dangle resolution function
  if w.resolve then
    out = out .. "static void\n" .. resolveFunc .. "(TState *T, " ..
      rstate .. " *R, " .. wstate ..
      " *W, Byte *finalImg, Byte *finalPtr)\n" ..
[[{
  Dangle *d;
  uintptr_t prev = 0, extras, n, off = finalPtr - finalImg;
  for (d = T->dangles->next, n = 0; d; d = d->next, n++);
  finalImg = excRealloc(finalImg, W->ptr - W->img + n * DANGLE_MAXLEN
                        + off);
  finalPtr = finalImg + off;
  for (d = T->dangles->next; d; d = d->next) {
    memcpy(finalPtr, W->img + prev, d->off - prev);
    finalPtr += d->off - prev;
    /* fooW_UInt must set extras */
]] ..
  "    " .. writes .. "W_UInt(&finalPtr, " .. reads ..
  "R_labelAddr(R, d->l).n);\n" ..
[[    prev = d->off + extras;
  }
  memcpy(finalPtr, W->img + prev,
         W->ptr - W->img - prev);
  finalPtr += W->ptr - W->img - prev;
  free(W->img);
  W->img = realloc(finalImg, finalPtr - finalImg);
  W->ptr = W->img + (finalPtr - finalImg);
}

]]
  end

  -- Writer Macros
  out = out .. "/* Writer macros */\n\n" ..
  w.macros .. "\n/* end of writer macros */\n\n"

  -- Head of the translator function
  out = out .. outputType .. " *\n" ..
    transFunc .. "(" .. inputType .. " *inp)\n" ..
[[{
  TState *T = translatorNew();
]] ..
  "  " .. rstate .. " *R = " .. reads .. "R_readerNew(inp);\n" ..
  "  " .. wstate .. " *W = " .. writes .. "W_writerNew();\n" ..
  "  " .. outputType .. " *out = new(" .. outputType .. ");\n" ..
[[  LabelType ty;
  Opcode o;
  /* reader declarations */
]] ..
 "  " .. r.trans.decls .. "\n" ..
 "  /* end of reader declarations */\n" ..
 "  /* writer declarations */\n" ..
 "  " .. w.trans.decls .. "\n" ..
 "  /* end of writer declarations */\n" ..
[[  for (ty = 0; ty < LABEL_TYPES; ty++)
    T->labels[ty] = 0;
  /* reader initialisation */
]] ..
 "  " .. r.trans.init .. "\n" ..
 "  /* end of reader initialisation */\n" ..
 "  /* writer initialisation */\n" ..
 "  " .. w.trans.init .. "\n" ..
 "  /* end of writer initialisation */\n" ..
 "  while (R->ptr < R->end) {\n" ..
 "    /* reader update */\n" ..
 "    " .. r.trans.update .. "\n" ..
 "    /* end of reader update */\n" ..
 "    /* writer update */\n" ..
 "    " .. w.trans.update .. "\n" ..
 "    /* end of writer update */\n" ..
 "    switch (o) {\n"

  -- The instruction cases
  for i = 1, getn(inst) do
    out = out .. "    case " .. opify(inst[i].name) .. ":\n" ..
      "      {\n"
    local inst = inst[i]
    for j = 1, getn(inst.ops) do
      local opTypeInfo = r.opType[inst.ops[j]]
      local decls = opTypeInfo.decls(inst, j)
      if decls ~= "" then
        out = out .. "        " .. decls .. "\n"
      end
    end
    for j = 1, getn(inst.ops) do
      local opTypeInfo = r.opType[inst.ops[j]]
      local code = opTypeInfo.code(inst, j)
      if code ~= "" then
        out = out .. "        " .. code .. "\n"
      end
    end
    out = out .. "        " .. w.inst[i].def .. ";\n" ..
      "        break;\n" ..
      "      }\n"
  end
  out = out ..
[[    default:
      throw(ExcBadInst);
]]

  -- End of the translator function
  out = out ..
[[    }
  }
  excPos = 0;
]]
  if w.resolve then
    out = out .."  " .. resolveFunc ..
      "(T, R, W, RESOLVE_IMG, RESOLVE_PTR);"
  end
  out = out ..
[[  /* reader finish */
]] ..
"  " .. r.trans.finish .. "\n" ..
"  /* end of reader finish*/\n" ..
"  /* writer finish */\n" ..
"  " .. w.trans.finish .. "\n" ..
"  /* end of writer finish */\n" ..
[[  return out;
}]]

  return out
end


-- Load list of reader-writer pairs
translators = dofile(transListFile)

-- Extract lists of readers and writers
readers = Set(project(1, translators))
for i, _ in readers do
  readers[i] = dofile(i .. "Read.lua")
end
writers = Set(project(2, translators))
for i, _ in writers do
  writers[i] = dofile(i .. "Write.lua")
end

-- Write the header file
writeto(transFile .. ".h") -- open the output file
writeLine("/* Mite translator",
          " * (c) Reuben Thomas",
          " */",
          "",
          "",
          "#ifndef MITE_TRANSLATORS",
          "#define MITE_TRANSLATORS",
          "",
          "",
          "#include \"translate.h\"",
          "")
for i, _ in writers do
  writeLine(writers[i].output)
end
for i, _ in readers do
  writeLine(readers[i].input)
end
for i = 1, getn(translators) do
  writeLine(translators[i][2] .. "W_Output *",
            transFunc(unpack(translators[i])) ..
              "(" .. translators[i][1] .. "R_Input *inp);\n")
end
writeLine("#endif")

-- Write the C file

writeto(transFile .. ".c") -- open the output file
writeLine("/* Mite translator",
          " * (c) Reuben Thomas",
          " *",
          " * Built with the following translators:",
          " *")

-- List the translators
for i = 1, getn(translators) do
  writeLine(" *   " .. translators[i][1] .. " -> " ..
            translators[i][2])
end

writeLine(" */\n") -- end of comment block
writeLine("#include \"" .. transFile .. ".h\"\n")
writeLine("#include \"translate.c\"")

-- Write the preludes
function writePrel(t)
  writeLine("\n\n/* " .. (t.reads or t.writes) .. " prelude */",
            t.prelude)
end
map(writePrel, values(readers))
map(writePrel, values(writers))

-- Write the translator functions
map(compose(writeLine, mkTrans), translators)

-- Mark the end
writeLine("\n\n/* End of Mite translator */")
