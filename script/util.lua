-- Lua utilities
-- (c) Reuben Thomas 2000

-- TODO: Document using same LuaDoc-like style as getopt.lua;
-- investigate actually using LuaDoc; need function names at start of
-- line 


-- Assertions, warnings, errors and tracing

-- Give warning with, optionally, the name of program and file
--   s: warning string
function warn(s)
  if prog.name then write(_STDERR, prog.name .. ": ") end
  if file then write(_STDERR, file .. ": ") end
  writeLine(_STDERR, s)
end

-- Die with error
--   s: error string
function die(s)
  warn(s)
  error()
end

-- Die with line number
--   s: error string
function dieLine(s)
  die(s .. " at line " .. line)
end

-- Die with error if value is nil
--   v: value
--   s: error string
function affirm(v, s)
  if not v then die(s) end
end

-- Die with error and line number if value is nil
--   v: value
--   s: error string
function affirmLine(v, s)
  if not v then dieLine(s) end
end

-- Print a debugging message
--   s: debugging message
function debug(s)
  if _DEBUG then writeLine(_STDERR, s) end
end



-- File

-- Find the length of a file
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

-- Guarded readfrom
--   [f]: file name
function readfrom(f)
  local h, err
  if f then h, err = %readfrom(f)
  else      h, err = %readfrom()
  end
  affirm(h, "can't read from " .. (f or "stdin") .. ": " ..
         (err or ""))
  return h
end

-- Guarded writeto
--   [f]: file name
function writeto(f)
  local h, err
  if f then h, err = %writeto(f)
  else      h, err = %writeto()
  end
  affirm(h, "can't write to " .. (f or "stdout") .. ": " ..
         (err or ""))
  return h
end

-- Guarded dofile
--   [f]: file name
function dofile(f)
  affirm(%dofile(f), "error while executing " .. f)
end

-- Guarded seek
--   f: file handle
--   w: whence to seek
--   o: offset
function seek(f, w, o)
  local ok, err
  if     o then ok, err = %seek(f, w, o)
  elseif w then ok, err = %seek(f, w)
  else          ok, err = %seek(f)
  end
  affirm(ok, "can't seek on " .. f .. ": " .. (err or ""))
end



-- Environment

-- Perform a shell command and return its output
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

-- Process all the files specified on the command-line with function f
-- f: process a file
--   name: the name of the file being read
--   i: the number of the argument
function processFiles(f)
  for i = 1, getn(arg) do
    if arg[i] == "-" then readfrom()
    else readfrom(arg[i])
    end
    file = arg[i]
    f(arg[i], i)
    readfrom() -- close file, if not already closed
  end
end


-- Data structures

-- Identity
--   x: object
-- returns
--   x: same object
function id(x)
  return x
end


-- Table and list functions

-- Map a function over a list
function map(f, l)
  local m = {}
  for i = 1, getn(l) do m[i] = f(l[i]) end
  return m
end

-- Map a function over a list of lists
function mapCall(f, l)
  local m = {}
  for i = 1, getn(l) do m[i] = call(f, l[i]) end
  return m
end

-- Apply a function to each element of a list
function apply(f, l)
  for i = 1, getn(l) do f(l[i]) end
end

-- Execute the members of a list as assignments (assumes the keys are
-- strings)
function assign(l)
  foreach(l, function (i, v) setglobal(i, v) end)
end

-- Turn a table into a list of lists
function listify(t)
  local l = {}
  foreach(t, function (i, v) tinsert(%l, {i,v}) end)
  return l
end

-- Call a function with values from 1..n, returning a list of results
function loop(n, f)
  local l = {}
  for i = 1, n do tinsert(l, f(i)) end
  return l
end

-- Concatenate two lists and return the result
function concat(l, m)
  local n = {}
  foreachi(l, function (i, v) tinsert(%n, v) end)
  foreachi(m, function (i, v) tinsert(%n, v) end)
  return n
end

-- Reverse a list and return the result
function reverse(l)
  local m = {}
  for i = getn(l), 1, -1 do tinsert(m, l[i]) end
  return m
end

-- Zip some lists together with a function
function zipWith(f, ls)
  local m, len = {}, getn(ls)
  for i = 1, call(max, map(getn, ls)) do
    local t = {}
    for j = 1, len do tinsert(t, ls[j][i]) end
    tinsert(m, call(f, t))
  end
  return m
end

-- Transpose a matrix (can be used to do unzip)
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

-- Project a list of fields from a list of records
--   l: list of records
--   f: field to project
-- returns
--   l: list of f fields
function project(l, f)
  local p = {}
  for i = 1, getn(l) do
    p[i] = l[i][f]
  end
  return p
end

-- Make an index for a list on the given field
function makeIndex(f, l)
  local ind = {}
  for i = 1, getn(l) do
    ind[l[i][f]] = i
  end
  return ind
end
  

-- Record constructor helper
-- turn a numbered list (list) into a record whose field names are
-- given by the list proto
function listToRec(proto, list)
  local t = {}
  foreachi(proto, function (i, v) %t[v] = %list[i] end)
  return t
end

-- Constructor maker: given a prototype, returns a record constructor
function constructor(proto)
  return (function (...) return listToRec(%proto, arg) end)
end



-- Text processing

-- Wrapper for buggy tinsert (Lua 4.0)
function tinsert(t, ...)
  if arg.n == 1 then %tinsert(t, arg[1])
  elseif arg.n >= 2 then %tinsert(t, arg[2], arg[2])
  else %tinsert(t)
  end
end

-- Write a line adding \n to the end
--   [fp]: file handle
--   s: string to write
function writeLine(fp, s)
  if not s then s, fp = fp, nil end
  if fp then write(fp, s .. "\n")
  else write(s .. "\n")
  end
end

-- Remove any final \n from a string
--   s: string to process
-- returns
--   s: processed string
function chomp(s)
  return gsub(s, "\n$", "")
end

-- Escape a string to be used as a pattern
--   s: string to process
-- returns
--   s: processed string
function escapePattern(s)
  s = gsub(s, "(%W)", "%%%1")
  return s
end

-- Escape a string to be used as a shell token (quote spaces and \s)
--   s: string to process
-- returns
--   s: processed string
function escapeShell(s)
  s = gsub(s, "([ %(%)])", "\\%1")
  return s
end

-- Turn a list of strings into a sep-separated string
--   sep: separator
--   l: list of strings to join
-- returns
--   s: joined up string
function join(sep, l)
  local len = getn(l)
  if len == 0 then return "" end
  local s = l[1]
  for i = 2, len do s = s .. sep .. l[i] end
  return s
end

-- Justify a string
--   s: string to justify
--   width: width to justify to (+ve means right-justify; negative
--     means left-justify)
--   [padder]: string to pad with (" " if omitted)
-- returns
--   s: justified string
function pad(s, width, padder)
  padder = strrep(padder or " ", abs(width))
  if width < 0 then return strsub(padder .. s, width) end
  return strsub(s .. padder, 1, width)
end

-- Wrap a string into a paragraph
--   s: string to wrap
--   w: width to wrap to [78]
--   i1: indent of first line [0]
--   i2: indent of subsequent lines [0]
-- returns
--   s: wrapped paragraph
function wrap(s, w, i1, i2)
  w = w or 78
  i1 = i1 or 0
  i2 = i2 or 0
  affirm(i1 < w and i2 < w,
         "wrap: the indents must be less than the line width")
  s = strrep(" ", i1) .. s
  local lstart, len = 1, strlen(s)
  while len - lstart > w do
    local i = lstart + w
    while i > lstart and strsub(s, i, i) ~= " " do i = i - 1 end
    local j = i
    while j > lstart and strsub(s, j, j) == " " do j = j - 1 end
    s = strsub(s, 1, j) .. "\n" .. strrep(" ", i2) ..
      strsub(s, i + 1, -1)
    local change = i2 + 1 - (i - j)
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
    if not l then break end
    tinsert(line, l)
  until nil
  return line
end

-- strfind-like wrapper for match
function rstrfind(s, p) return match(s, regex(p)) end

-- wrapper for gmatch
function rgmatch(s, p, r) return gmatch(s, regex(p), r) end

-- write a gsub-like wrapper for match
-- really needs to be in C for speed
-- function rgsub(s, p, r) ... end



-- Utilities

-- Extend tostring to work better on tables
-- make it output in {a,b,c...;x1=y1,x2=y2...} format; use nexti
-- only output the LH part if there is a table.n and members 1..n
--   x: object to convert to string
-- returns
--   s: string representation
function tostring(x)
  local s
  if type(x) == "table" then
    s = "{"
    local i, v = next(x)
    while i do
      s = s .. tostring(i) .. "=" .. tostring(v)
      i, v = next(x, i)
      if i then s = s .. "," end
    end
    return s .. "}"
  else return %tostring(x)
  end
end

-- Extend print to work better on tables
--   arg: objects to print
function print(...)
  for i = 1, getn(arg) do arg[i] = tostring(arg[i]) end
  call(%print, arg)
end
