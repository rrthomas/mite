-- Lua utilities
-- (c) Reuben Thomas 2000


-- TODO: LuaDocify, LTN7-ify (one file per module)
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   variable names)
-- TODO: When Lua 4.1 is released, kick this out of Mite SF and have a
--   new SF project StdLua (require should use LUALIB env var as a
--   path variable)
-- TODO: Add a set table type with elem, ==, + (union), - (set
--   difference) and / (intersection) operations
-- TODO: Implement hslibs pretty-printing (sdoc) routines (use .. for
--   <> and + for <+>)



-- Data structures

-- id: Identity
--   x: object
-- returns
--   x: same object
function id(x)
  return x
end

-- loop: Call a function with values from 1..n, returning a list of
-- results
--   n: upper limit of parameters to function
--   f: function
-- returns
--   l: list {f(1) .. f(n)}
function loop(n, f)
  local l = {}
  for i = 1, n do
    tinsert(l, f(i))
  end
  return l
end


-- Globals

-- newGlobalType: Make a new global variable type
--   get: getglobal tag method
--   set: setglobal tag method
-- returns
--   tag: tag of new global type
function newGlobalType(get, set)
  local tag = newtag()
  settagmethod(tag, "getglobal", get)
  settagmethod(tag, "setglobal", set)
  return tag
end

-- newGlobal: Make a special global variable
-- If a tag is supplied, that type is used; otherwise, a uniquely
-- tagged variable with the given methods is created
--   (tag: tag of the special type
--   ( or
--   (get: get tag method
--   (set: set tag method
-- returns
--   t: value of new global
function newGlobal(get, set)
  local t, tag = {}, get
  if type(tag) ~= "number" then
    tag = newGlobalType(get, set)
  end
  settag(t, tag)
  return t
end

-- newMacro: Make a global to get and set an lvalue
--   e: the expression to evaluate for the lvalue
-- returns
--   t: value of new global
function newMacro(e)
  return newGlobal(dostring("return function (n, v) return " .. e .. " end"),
                   dostring("return function (n, o, v) " .. e .. " = v end"))
end

-- newReadOnlyMacro: Make a read-only global expression
--   e: the expression to evaluate for the lvalue
-- returns
--   t: value of new global
function newReadOnlyMacro(e)
  return newGlobal(dostring("return function (n, v) return " .. e .. " end"),
                   function (n, o, v) error("read-only value") end)
end

-- newConstant: Make a global constant
--   c: value of the constant
-- returns
--   t: value of new global
function newConstant(c)
  return newGlobal(function (n, v) return %c end,
                   function (n, o, v) error("constant value") end)
end


-- Tables

-- Tag methods for tables
-- table + table = merge
settagmethod(tag({}), "add",
             function (t, u)
               if type(u) ~= "table" then
                 die("table expected")
               end
               return merge(t, u)
             end)

-- tinsert: Wrapper for buggy tinsert (Lua 4.0)
--   t: table
--   ...: items to insert
if _VERSION == "Lua 4.0" then
  function tinsert(t, ...)
    if arg.n == 1 then
      %tinsert(t, arg[1])
    elseif arg.n >= 2 then
      %tinsert(t, arg[1], arg[2])
    else
      %tinsert(t)
    end
  end
end

-- indices: Return a list of indices of a table
--   t: table
-- returns
--   u: table of indices
function indices(t)
  local u = {}
  for i, v in t do
    tinsert(u, i)
  end
  return u
end

-- values: Return a list of values of a table
--   t: table
-- returns
--   u: table of values
function values(t)
  local u = {}
  for i, v in t do
    tinsert(u, v)
  end
  return u
end

-- reindex: Change the keys of a table
--   p: list of oldkey=newkey
--   t: table to reindex
-- returns
--   u: reindexed table
function reindex(p, t)
  local u = {}
  for o, n in p do
    u[n] = t[o]
  end
  return u
end

-- assign: Execute the elements of a table as assignments (assumes the
-- keys are strings)
--   l: list
function assign(l)
  for i, v in l do
    setglobal(i, v)
  end
end

-- listify: Turn a table into a list of lists
--   t: table {i1=v1 .. in=vn}
-- returns
--   ls: list {{i1, v1} .. {in, vn}}
function listify(t)
  local ls = {}
  for i, v in t do
    tinsert(ls, {i, v})
  end
  return ls
end


-- Lists

-- Tag methods for lists
-- list * number = repeat the list
-- list .. list = concat
settagmethod(tag({}), "concat",
             function (t, u)
               if type(u) ~= "table" then
                 die("table expected")
               end
               return concat(t, u)
             end)
settagmethod(tag({}), "mul",
             function (t, n)
               if type(n) ~= "number" then
                 die("number expected")
               end
               local u = {}
               for i = 1, n do
                 u = u .. t
               end
               return u
             end)

-- map: Map a function over a list
--   f: function
--   l: list
-- returns
--   m: result list {f(l[1]) .. f(l[getn(l)])}
function map(f, l)
  local m = {}
  for i = 1, getn(l) do
    m[i] = f(l[i])
  end
  return m
end

-- mapCall: Map a function over a list of lists
--   f: function
--   ls: list of lists
-- returns
--   m: result list {call(f, ls[1]) .. call(f, ls[getn(ls)])}
function mapCall(f, l)
  local m = {}
  for i = 1, getn(l) do
    m[i] = call(f, l[i])
  end
  return m
end

-- apply: Apply a function to each element of a list
--   f: function
--   l: list
function apply(f, l)
  for i = 1, getn(l) do
    f(l[i])
  end
end

-- foldl: Fold a binary function left to right through a list
--   f: function
--   e: element to place in left-most position
--   l: list
-- returns
--   r: result
function foldr(f, e, l)
  local r = e
  for i = 1, getn(l) do
    r = f(r, l[i])
  end
  return r
end

-- shift: remove elements from the front of a list
--   l: list to remove elements from [defaults to arg]
--   n: number of elements to remove [defaults to 1]
function shift(l, n)
  if not n then
    if type(l) == "number" then
      l, n = arg, l
    else
      n = 1
    end
  end
  for i = 1, n do
    tremove(l, 1)
  end
end

-- concat: Concatenate two lists
--   l: list
--   m: list
-- returns
--   n: result {l[1] .. l[getn(l)], m[1] .. m[getn(m)]}
function concat(l, m)
  local n = {}
  for i = 1, getn(l) do
    tinsert(n, l[i])
  end
  for i = 1, getn(m) do
    tinsert(n, m[i])
  end
  return n
end

-- reverse: Reverse a list
--   l: list
-- returns
--   m: list {l[getn(l)] .. l[1]}
function reverse(l)
  local m = {}
  for i = getn(l), 1, -1 do
    tinsert(m, l[i])
  end
  return m
end

-- transpose: Transpose a list of lists
--   ls: {{l11 .. l1c} .. {lr1 .. lrc}}
-- returns
--   ms: {{l11 .. lr1} .. {l1c .. lrc}}
-- Also give aliases zip and unzip
function transpose(ls)
  local ms, len = {}, getn(ls)
  for i = 1, call(max, map(getn, ls)) do
    ms[i] = {}
    for j = 1, len do
      tinsert(ms[i], ls[j][i])
    end
  end
  return ms
end
zip = transpose
unzip = transpose

-- zipWith: Zip lists together with a function
--   f: function
--   ls: list of lists
-- returns
--   m: {f(ls[1][1], .., ls[getn(ls)][1]) ..
--         f(ls[1][N], .., ls[getn(ls)][N])
--   where N = call(max, map(getn, ls))
function zipWith(f, ls)
  local m, len = {}, getn(ls)
  for i = 1, call(max, map(getn, ls)) do
    local t = {}
    for j = 1, len do
      tinsert(t, ls[j][i])
    end
    tinsert(m, call(f, t))
  end
  return m
end

-- project: Project a list of fields from a list of tables
--   f: field to project
--   l: list of tables
-- returns
--   p: list of f fields
function project(f, l)
  local p = {}
  for i = 1, getn(l) do
    p[i] = l[i][f]
  end
  return p
end

-- merge: Merge two tables
-- If there are duplicate fields, the right hand table's will be used
--   t, u: tables
-- returns
--   r: the merged table
function merge(t, u)
  local r = {}
  for i, v in t do
    r[i] = v
  end
  for i, v in u do
    r[i] = v
  end
  return r
end

-- index: Make an index for a list of tables on the given field
--   f: field
--   l: list of tables {{i1=v11 .. in=v1n} .. {i1=vm1 .. in=vmn}}
-- returns
--   ind: index {l[1][f]=1 .. l[m][f]=m}
function index(f, l)
  local ind = {}
  for i = 1, getn(l) do
    local v = l[i][f]
    if v then
      ind[v] = i
    end
  end
  return ind
end

-- permute: Permute a list
--   p: list of new positions
--   l: list to permute
-- returns
--   m: permuted list
permute = reindex

-- permuteOn: Permute a list on a given field
--   f: field whose value should be used as key
--   l: list to permute
-- returns
--   m: permuted list
function permuteOn(f, l)
  return permute(project(f, l), l)
end


-- listToTab: Table constructor helper
-- turn a numbered list (list) into a table whose field names are
-- given by the list proto
--   proto: {field1 .. fieldn}
--   list: {v1 .. vn}
-- returns
--   t: {field1=v1 .. fieldn=vn}
function listToTab(proto, list)
  local t = {}
  for i = 1, getn(proto) do
    t[proto[i]] = list[i]
  end
  return t
end

-- constructor: Make a prototype from a table constructor
--   proto: {field1 .. fieldn}
-- returns
--   f:
--     list: {v1 .. vn}
--   returns
--     t: {field1=v1 .. fieldn=vn}
function constructor(proto)
  return (function (...)
            return listToTab(%proto, arg)
          end)
end



-- Text processing

-- writeLine: Write values adding a newline after each
--   [fp]: file handle
--   ...: values to write (as for write)
function writeLine(fp, ...)
  if tag(fp) ~= tag(_STDERR) then
    tinsert(arg, 1, fp)
    fp = nil
  end
  for i = 1, getn(arg) do
    if fp then
      write(fp, arg[i])
    else
      write(arg[i])
    end
    write("\n")
  end
end

-- chomp: Remove any final \n from a string
--   s: string to process
-- returns
--   s_: processed string
function chomp(s)
  return gsub(s, "\n$", "")
end

-- escapePattern: Escape a string to be used as a pattern
-- TODO: rewrite for 4.1 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function escapePattern(s)
  s = gsub(s, "(%W)", "%%%1")
  return s
end

-- escapeShell: Escape a string to be used as a shell token (quote
-- spaces and \s)
-- TODO: rewrite for 4.1 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function escapeShell(s)
  s = gsub(s, "([ %(%)])", "\\%1")
  return s
end

-- split: Turn a string into a list of strings, breaking at sep
--   sep: separator character
--   s: string to split
-- returns
--   l: list of strings
function split(sep, s)
  local l = {}
  gsub(s, "([^" .. sep .. "]+)",
       function (s)
         tinsert(%l, s)
       end)
  return l
end

-- join: Turn a list of strings into a sep-separated string
--   sep: separator
--   l: list of strings to join
-- returns
--   s: joined up string
function join(sep, l)
  local len = getn(l)
  if len == 0 then
    return ""
  end
  local s = l[1]
  for i = 2, len do
    s = s .. sep .. l[i]
  end
  return s
end

-- strcaps: Capitalise each word in a string
--   s: string
-- returns
--   s_: capitalised string
-- TODO: rewrite for 4.1 using bracket notation
function strcaps(s)
  s = gsub(s, "(%w)([%w]*)",
           function (l, ls)
             return strupper(l) .. ls
           end)
  return s
end

-- pad: Justify a string
--   s: string to justify
--   width: width to justify to (+ve means right-justify; negative
--     means left-justify)
--   [padder]: string to pad with (" " if omitted)
-- returns
--   s_: justified string
function pad(s, width, padder)
  padder = strrep(padder or " ", abs(width))
  if width < 0 then
    return strsub(padder .. s, width)
  end
  return strsub(s .. padder, 1, width)
end

-- wrap: Wrap a string into a paragraph
--   s: string to wrap
--   w: width to wrap to [78]
--   ind: indent [0]
--   ind1: indent of first line [ind]
-- returns
--   s_: wrapped paragraph
function wrap(s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  affirm(ind1 < w and ind < w,
         "wrap: the indents must be less than the line width")
  s = strrep(" ", ind1) .. s
  local lstart, len = 1, strlen(s)
  while len - lstart > w do
    local i = lstart + w
    while i > lstart and strsub(s, i, i) ~= " " do
      i = i - 1
    end
    local j = i
    while j > lstart and strsub(s, j, j) == " " do
      j = j - 1
    end
    s = strsub(s, 1, j) .. "\n" .. strrep(" ", ind) ..
      strsub(s, i + 1, -1)
    local change = ind + 1 - (i - j)
    lstart = j + change
    len = len + change
  end
  return s
end

-- readLines: read _INPUT into a list of lines
-- returns
--   line: list of lines
function readLines()
  local line = {}
  repeat
    local l = read("*l")
    if not l then
      break
    end
    tinsert(line, l)
  until nil
  return line
end

-- gsubs: perform multiple calls to gsub
--   s: string to call gsub on
--   sub: list of {pattern, replacement}
--   [n]: upper limit on replacements
-- returns
--   s_: result string
--   n_: number of replacements made
function gsubs(s, sub, n)
  local n_ = 0
  for i, v in sub do
    local r
    if n then
      s, r = gsub(s, i, v, n)
      n_ = n_ + r
      n = n - r
      if n == 0 then
        break
      end
    else
      s, r = gsub(s, i, v)
      n_ = n_ + r
    end
  end
  return s, n_
end

-- rstrfind: strfind-like wrapper for match
--   s: target string
--   p: pattern
-- returns
--   m: first match of p in s
function rstrfind(s, p)
  return match(s, regex(p))
end

-- rgmatch: wrapper for gmatch
--   s: target string
--   p: pattern
--   r:
--     t: table of captures
--   returns
--     rep: replacement
-- returns
--   n: number of matches
function rgmatch(s, p, r)
  return gmatch(s, regex(p), r)
end

-- TODO: rgsub: gsub-like wrapper for match
-- really needs to be in C for speed
-- function rgsub(s, p, r) ... end



-- Assertions, warnings, errors and tracing

-- warn: Give warning with the name of program and file (if any)
--   s: warning string
function warn(s)
  if prog.name then
    write(_STDERR, prog.name .. ":")
  end
  if prog.file then
    write(_STDERR, prog.file .. ":")
  end
  if prog.line then
    write(_STDERR, tostring(prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    write(_STDERR, " ")
  end
  writeLine(_STDERR, s)
end

-- die: Die with error
--   s: error string
function die(s)
  warn(s)
  error()
end

-- affirm: Die with error if value is nil
--   v: value
--   s: error string
function affirm(v, s)
  if not v then
    die(s)
  end
end

-- debug: Print a debugging message
--   s: debugging message
function debug(s)
  if _DEBUG then
    writeLine(_STDERR, s)
  end
end



-- File

-- lenFile: Find the length of a file
--   f: file name
-- returns
--   len: length of file
function lenFile(f)
  local h, len
  h = openfile(f, "r")
  len = seek(h, "end")
  closefile(h)
  return len
end

-- readfrom: Guarded readfrom
--   [f]: file name
-- returns
--   h: handle
local _readfrom = readfrom
function readfrom(f)
  local h, err
  if f then
    h, err = %_readfrom(f)
  else
    h, err = %_readfrom()
  end
  affirm(h, "can't read from " .. (f or "stdin") .. ": " ..
         (err or ""))
  return h
end

-- writeto: Guarded writeto
--   [f]: file name
-- returns
--   h: handle
local _writeto = writeto
function writeto(f)
  local h, err
  if f then
    h, err = %_writeto(f)
  else
    h, err = %_writeto()
  end
  affirm(h, "can't write to " .. (f or "stdout") .. ": " ..
         (err or ""))
  return h
end

-- dofile: Guarded dofile
--   [f]: file name
-- returns
--   r: result of dofile
local _dofile = dofile
function dofile(f)
  local r = %_dofile(f)
  affirm(r, "error while executing " .. f)
  return r
end

-- seek: Guarded seek
--   f: file handle
--   w: whence to seek
--   o: offset
local _seek = seek
function seek(f, w, o)
  local ok, err
  if o then
    ok, err = %_seek(f, w, o)
  elseif w then
    ok, err = %_seek(f, w)
  else
    ok, err = %_seek(f)
  end
  affirm(ok, "can't seek on " .. f .. ": " .. (err or ""))
end



-- Environment

-- shell: Perform a shell command and return its output
--   c: command
-- returns
--   o: output
function shell(c)
  local input = _INPUT
  local o, h
  h = readfrom("|" .. c)
  o = read("*a")
  closefile(h)
  _INPUT = input
  return o
end

-- processFiles: Process files specified on the command-line
--   f: function to process files with
--     name: the name of the file being read
--     i: the number of the argument
function processFiles(f)
  for i = 1, getn(arg) do
    if arg[i] == "-" then
      readfrom()
    else
      readfrom(arg[i])
    end
    prog.file = arg[i]
    f(arg[i], i)
    readfrom() -- close file, if not already closed
  end
end



-- Utilities

-- tostring: Extend tostring to work better on tables
-- TODO: make it output in {v1, v2 ..; x1=y1, x2=y2 ..} format; use
-- nexti; show the n field (if any) on the RHS
--   x: object to convert to string
-- returns
--   s: string representation
local _tostring = tostring
function tostring(x)
  local s
  if type(x) == "table" then
    s = "{"
    local i, v = next(x)
    while i do
      s = s .. tostring(i) .. "=" .. tostring(v)
      i, v = next(x, i)
      if i then
        s = s .. ","
      end
    end
    return s .. "}"
  end
  return %_tostring(x)
end

-- print: Extend print to work better on tables
--   arg: objects to print
local _print = print
function print(...)
  for i = 1, getn(arg) do
    arg[i] = tostring(arg[i])
  end
  call(%_print, arg)
end

-- traceCall: trace function calls
-- Use: setcallhook(traceCall), as below
-- based on lua/test/trace-calls.lua
function traceCall(func)
  local t = getinfo(2)
  local name = t.name or "?"
  local s = ">>> "
  if t.what == "main" then
    if func == "call" then
      s = s .. "begin " .. t.source
    else
      s = s .. "end " .. t.source
    end
  else
    s = s .. func .. " " .. name
    if t.what == "Lua" then
      s = s .. " <" .. t.linedefined .. ":" .. t.source .. ">"
    else
      s = s .. " [" .. t.what .. "]"
    end
  end
  if t.currentline >= 0 then
    s = ":" .. t.currentline
  end
  writeLine(_STDERR, s)
end

-- Set hooks according to _DEBUG
if _DEBUG and type(_DEBUG) == "table" then
  if _DEBUG.call then
    setcallhook(traceCall)
  end
end
