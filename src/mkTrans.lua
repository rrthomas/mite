-- Mite translator program generator
-- Generate a C file for a collection of translators
-- (c) Reuben Thomas 2002


transListFile, transFile = arg[1], arg[2]


-- Global formatting parameter
instWidth = 36


-- Constructors

-- Reader type
--   reads: what the reader reads
--   input: input type
--   prelude: literal source code
--   opType: operand type reader table
--   trans: reader-specific parts of translator function  

-- Writer type
--   writes: what the writer writes
--   output: output type
--   prelude: literal source code
--   resolve: dangles resolution macros
--   macros: writer macros
--   inst: instruction table
--   trans: writer-specific parts of translator function

-- Instrumenter type
--   instrument: the instrumentation provided
--   prelude: literal source code
--   macros: instrumenter macros
--   inst: instruction table
--   trans: instrumenter-specific parts of translator function

OpType =
  function (arg)
    local decls, code = arg[1], arg[2]
    -- decls: declarations for the operand reading code
    -- code: code to read an operand of the given type
    -- each is either a string, or a function (inst, op) ->
    -- string
    -- in the output, %n -> operand no.
    function funcify (f)
      if type (f) ~= "function" then
        f = function (inst, op)
              return %f
            end
      end
      return function (inst, opNo)
               local s = %f (inst, opNo)
               return gsub (s, "%%n", tostring (opNo))
             end
    end
    local t = {decls = funcify (decls), code = funcify (code)}
    return t
  end

Inst = Object {_init = {
    "name", -- instruction name
    "def",  -- definition
}}

Translator = Object {_init = {
    "decls",  -- extra variable declarations
    "init",   -- extra initialisation
    "update", -- update after reading each instruction
    "finish", -- code to execute after translation and resolution
}}


-- Code construction helper functions

function transFunc (reads, writes)
  return reads .. "To" .. strcaps (writes)
end

function mkBlock (title, code, indent)
  return format ("%s/* %s */\n%s%s\n%s/* end of %s */\n",
                 indent, title, indent, code, indent, title)
end


-- Main code construction function

function mkTrans (arg)
  local reads, writes, instrumentation = arg[1], arg[2], arg[3]

  -- Load the reader and writer
  local r = readers[reads]
  local w = writers[writes]
  local instrum = {n = 0}
  if instrumentation then
    for i = 1, getn (instrumentation) do
      tinsert (instrum, instrumenters[instrumentation[i]])
    end
  end
  local transFunc = transFunc (reads, writes)
  local resolveFunc = "resolveDangles" .. strcaps (transFunc)
  local rstate, wstate = reads .. "R_State", writes .. "W_State"
  local inputType = reads .. "R_Input"
  local outputType = writes .. "W_Output"

  local mkInstrumentation =
    function (title, path, indent)
      local out = ""
      for i = 1, getn (%instrum) do
        out = out .. mkBlock (%instrum[i].instrument .. " " .. title,
                              lookup (%instrum[i], path), indent)
      end
      return out
    end

  local mkInsert =
    function (title, field, indent)
      return mkBlock ("reader " .. title, %r.trans[field], indent) ..
        mkBlock("writer " .. title, %w.trans[field], indent) ..
        %mkInstrumentation (title, {"trans", field}, indent)
    end

  -- Check the reader implements the correct opTypes
  assert (setequal (Set (project ("name", opType)),
                  Set (project (1, enpair (r.opType)))),
         "incorrect opType in " .. r.reads .. " reader")

  -- Check the writer implements the correct instructions
  for i = 1, getn (inst) do
    assert (w.inst[i], "instruction " .. inst[i].name .. " missing")
    assert (w.inst[i].name == inst[i].name,
           "instruction " .. tostring (i) .. " ('" .. w.inst[i].name ..
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
  finalImg = excRealloc (finalImg, W->ptr - W->img + n * ]] ..
  writes .. [[W_DANGLE_MAXLEN
                        + off);
  finalPtr = finalImg + off;
  for (d = T->dangles->next; d; d = d->next) {
    memcpy (finalPtr, W->img + prev, d->off - prev);
    finalPtr += d->off - prev;
]] ..
  "    /* " .. writes .. "W_UInt must set extras */\n" ..
  "    " .. writes .. "W_UInt (&finalPtr, " .. reads ..
  "R_labelAddr (R, d->l).n);\n" ..
[[    prev = d->off + extras;
  }
  memcpy (finalPtr, W->img + prev,
         W->ptr - W->img - prev);
  finalPtr += W->ptr - W->img - prev;
  free (W->img);
  W->img = realloc (finalImg, finalPtr - finalImg);
  W->ptr = W->img + (finalPtr - finalImg);
}

]]
  end

  -- Writer Macros
  out = out .. mkBlock ("writer macros", w.macros, "") ..
    mkInstrumentation ("macros", {"macros"}, "")

  -- Head of the translator function
  out = out .. "\n" .. outputType .. " *\n" ..
    transFunc .. "(" .. inputType .. " *inp)\n" ..
[[{
  TState *T = translatorNew ();
]] ..
  "  " .. rstate .. " *R = " .. reads .. "R_readerNew (inp);\n" ..
  "  " .. wstate .. " *W = " .. writes .. "W_writerNew ();\n" ..
  "  " .. outputType .. " *out = new (" .. outputType .. ");\n" ..
[[  LabelType ty;
  Opcode o;
]] ..
  mkInsert ("declarations", "decls", "  ") ..
[[  for (ty = 0; ty < LABEL_TYPES; ty++)
    T->labels[ty] = 0;
]] ..
 mkInsert ("initialisation", "init", "  ") ..
 "  while (R->ptr < R->end) {\n" ..
 mkInsert ("update", "update", "    ") ..
 "    switch (o) {\n"

  -- The instruction cases
  for i = 1, getn (inst) do
    out = out .. "    case " .. opify (inst[i].name) .. ":\n" ..
      "      {\n"
    local inst = inst[i]

    for j = 1, getn (inst.ops) do
      local opType = inst.ops[j]
      local opRepeat
      if strsub (opType, -1, -1) == "+" then
        opType = strsub (opType, 1, -2)
        opRepeat = 1
      end
      local opTypeInfo = r.opType[opType]

      local decls = opTypeInfo.decls (inst, j)
      if decls ~= "" then
        out = out .. "        " .. decls .. "\n"
      end

      local code = opTypeInfo.code (inst, j)
      if code ~= "" then
        out = out .. "        " .. code .. "\n"
      end
    end

    for j = 1, getn (instrum) do
      out = out .. "        " .. instrum[j].inst[i].def .. ";\n"
    end
    out = out .. "        " .. w.inst[i].def .. ";\n" ..
      "        break;\n" ..
      "      }\n"
  end
  out = out ..
[[    default:
      die (ExcBadInst);
]]

  -- End of the translator function
  out = out ..
[[    }
  }
  excPos = 0;
]]
  if w.resolve then
    out = out .."  " .. resolveFunc ..
      "(T, R, W, " .. writes .. "W_RESOLVE_IMG, " .. writes ..
      "W_RESOLVE_PTR);\n"
  end
  out = out .. mkInsert ("finish", "finish", "  ") ..
[[  return out;
}]]

  return out
end


-- Load list of reader-writer pairs
translators = dofile (transListFile)

-- Extract lists of readers and writers
readers = Set (project (1, translators))
for i, _ in readers do
  readers[i] = dofile (i .. "Read.lua")
end
writers = Set (project (2, translators))
for i, _ in writers do
  writers[i] = dofile (i .. "Write.lua")
end
instrumenters = Set (flatten (project (3, translators)))
for i, _ in instrumenters do
  instrumenters[i] = dofile (i .. ".lua")
end


-- Write the header file
writeto (transFile .. ".h") -- open the output file
writeLine ("/* Mite translator",
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
  writeLine (writers[i].output)
end
for i, _ in readers do
  writeLine (readers[i].input)
end
for i = 1, getn (translators) do
  writeLine (translators[i][2] .. "W_Output *",
            transFunc (unpack (translators[i])) ..
              "(" .. translators[i][1] .. "R_Input *inp);\n")
end
writeLine ("#endif")

-- Write the C file

writeto (transFile .. ".c") -- open the output file
writeLine ("/* Mite translator",
          " * (c) Reuben Thomas",
          " *",
          " * Built with the following translators:",
          " *")

-- List the translators
for i = 1, getn (translators) do
  writeLine (" *   " .. translators[i][1] .. " -> " ..
            translators[i][2])
end

writeLine (" */\n") -- end of comment block
writeLine ("#include \"" .. transFile .. ".h\"\n")
writeLine ("#include \"translate.c\"")

-- Write the preludes and resolver macros
function writeBlock (s, f, t)
  if t[f] then
    writeLine ("\n" .. mkBlock ((t.reads or t.writes or t.instrument)
                                .. " " .. s,
                                t[f], ""))
  end
end

map (curry (writeBlock, "reader prelude", "prelude"),
     values (readers))
map (curry (writeBlock, "writer prelude", "prelude"),
     values (writers))
map (curry (writeBlock, "prelude", "prelude"),
     values (instrumenters))
map (curry (writeBlock, "resolver macros", "resolve"),
     values (writers))

-- Write the translator functions
map (compose (writeLine, mkTrans), translators)

-- Mark the end
writeLine ("\n\n/* end of Mite translator */")
