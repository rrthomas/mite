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
--   inst: instruction table
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

Inst = Object {_init = {
    "name", -- instruction name
    "decl", -- declarations
    "code", -- code
}}

Translator = Object {_init = {
    "decls",  -- extra variable declarations
    "init",   -- extra initialisation
    "update", -- update after reading each instruction
    "final",  -- code to execute after translation and resolution
}}


-- Code construction helper functions

function transFunc (reads, writes)
  return reads .. "To" .. string.caps (writes)
end

function mkBlock (title, code, indent)
  return string.format ("%s/* %s */\n%s%s\n%s/* end of %s */\n",
                        indent, title, indent, code, indent, title)
end

-- Given a compound operand type (type plus optional letter), return
-- the basic type and a flag indicating whether it repeats
function getOpInfo (opType)
  local opRepeat
  if opType:sub (-1, -1) == "+" then
    opType = opType:sub (1, -2)
    opRepeat = 1
  end
  return opType, opRepeat
end

-- Check the reader implements the correct opTypes
function checkReaderOpTypes (opType, r, rOpType)
  if not std.set.equal (std.set (std.table.project ("name", opType)),
                        std.set (std.table.project (1, std.table.enpair (rOpType))))
  then
    print ("opType: " .. std.set (std.table.project ("name", opType)))
    print ("rOpType: " .. std.set (std.table.project (1, std.table.enpair (rOpType))))
    -- FIXME: use die
    assert (false, "incorrect opType in " .. r.reads .. " reader")
  end
end


-- Main code construction function

function mkTrans (arg)
  local reads, writes, instrumentation = arg[1], arg[2], arg[3]

  -- Load the reader and writer
  local r = readers[reads]
  local w = writers[writes]
  local instrum = {n = 0}
  if instrumentation then
    for i = 1, #instrumentation do
      tinsert (instrum, instrumenters[instrumentation[i]])
    end
  end
  local transFunc = transFunc (reads, writes)
  local resolveFunc = "resolveDangles" .. string.caps (transFunc)
  local rstate, wstate = reads .. "R_State", writes .. "W_State"
  local inputType = reads .. "R_Input"
  local outputType = writes .. "W_Output"

  local mkInstrumentation =
    function (title, path, indent)
      local out = ""
      for i = 1, #instrum do
        out = out .. mkBlock (instrum[i].instrument .. " " .. title,
                              lookup (instrum[i], path), indent)
      end
      return out
    end

  local mkInsert =
    function (title, field, indent)
      return mkBlock ("reader " .. title, r.trans[field], indent) ..
        mkBlock("writer " .. title, w.trans[field], indent) ..
        mkInstrumentation (title, {"trans", field}, indent)
    end

  -- Check the reader and writer implement the correct instructions
  for i = 1, #inst do
    assert (r.inst[i],
            "reader instruction " .. inst[i].name .. " missing")
    assert (w.inst[i],
            "writer instruction " .. inst[i].name .. " missing")
    assert (r.inst[i].name == inst[i].name,
            "reader instruction " .. tostring (i) .. " ('" ..
              w.inst[i].name .. "') should be '" .. inst[i].name ..
              "'")
    assert (w.inst[i].name == inst[i].name,
            "writer instruction " .. tostring (i) .. " ('" ..
              w.inst[i].name .. "') should be '" .. inst[i].name ..
              "'")
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
  "    " .. writes .. "W_UInt(&finalPtr, " .. reads ..
  "R_labelAddr(R, d->l).n);\n" ..
[[    prev = d->off + extras;
  }
  memcpy(finalPtr, W->img + prev, W->ptr - W->img - prev);
  finalPtr += W->ptr - W->img - prev;
  free(W->img);
  W->img = realloc(finalImg, finalPtr - finalImg);
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
  "  " .. rstate .. " *R = " .. reads .. "R_readerNew(inp);\n" ..
  "  " .. wstate .. " *W = " .. writes .. "W_writerNew();\n" ..
  "  " .. outputType .. " *out = new(" .. outputType .. ");\n" ..
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
  for i = 1, #inst do
    -- Start of case
    out = out .. "    case " .. opify (inst[i].name) .. ":\n" ..
      "      {\n"
    local inst = inst[i]

    -- Output declarations
    out = out .. r.inst[i].decl .. "\n"
    for j = 1, #instrum do
      out = out .. instrum[j].inst[i].decl .. "\n"
    end
    out = out .. w.inst[i].decl .. "\n"
    
    -- Output main code
    out = out .. r.inst[i].code .. "\n"
    for j = 1, #instrum do
      out = out .. instrum[j].inst[i].code .. "\n"
    end
    out = out .. w.inst[i].code .. "\n"

    -- End of case
    out = out .. [[        break;
      }
]]
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
  out = out .. mkInsert ("finalisation", "final", "  ") ..
[[  return out;
}]]

  return out
end


-- Load list of reader-writer pairs
translators = dofile (transListFile)

-- Extract lists of readers and writers
readers = table.invert (std.table.project (1, translators))
for i in pairs (readers) do
  readers[i] = dofile (miteDir .. "/src/" .. i .. "Read.lua")
end
writers = table.invert (std.table.project (2, translators))
for i in pairs (writers) do
  writers[i] = dofile (miteDir .. "/src/" .. i .. "Write.lua")
end
instrumenters = table.invert (std.table.flatten (std.table.project (3, translators)))
for i in pairs (instrumenters) do
  instrumenters[i] = dofile (miteDir .. "/src/" .. i .. ".lua")
end


-- Write the header file
io.output (transFile .. ".h") -- open the output file
io.writelines ("/* Mite translator",
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
for i in pairs (writers) do
  io.writelines (writers[i].output)
end
for i in pairs (readers) do
  io.writelines (readers[i].input)
end
for i = 1, #translators do
  io.writelines (translators[i][2] .. "W_Output *",
                 transFunc (table.unpack (translators[i])) ..
                   "(" .. translators[i][1] .. "R_Input *inp);\n")
end
io.writelines ("#endif")


-- Write the C file

io.output (transFile .. ".c") -- open the output file
io.writelines ("/* Mite translator",
               " * (c) Reuben Thomas",
               " *",
               " * Built with the following translators:",
               " *")

-- List the translators
for i = 1, #translators do
  io.writelines (" *   " .. translators[i][1] .. " -> " ..
                   translators[i][2])
end

io.writelines (" */\n") -- end of comment block
io.writelines ("#include \"" .. transFile .. ".h\"\n")
io.writelines ("#include \"translate.c\"")

-- Write the preludes and resolver macros
function writeBlock (s, f, t)
  if t[f] then
    io.writelines ("\n" .. mkBlock ((t.reads or t.writes or t.instrument)
                                      .. " " .. s,
                                    t[f], ""))
  end
end

std.functional.map (std.functional.bind (writeBlock, {"reader prelude", "prelude"}),
                    std.ielems, table.values (readers))
std.functional.map (std.functional.bind (writeBlock, {"writer prelude", "prelude"}),
                    std.ielems, table.values (writers))
std.functional.map (std.functional.bind (writeBlock, {"prelude", "prelude"}),
                    std.ielems, table.values (instrumenters))
std.functional.map (std.functional.bind (writeBlock, {"resolver macros", "resolve"}),
                    std.ielems, table.values (writers))

-- Write the translator functions
std.functional.map (std.functional.compose (mkTrans, io.writelines), std.ielems, translators)

-- Mark the end
io.writelines ("\n\n/* end of Mite translator */")
