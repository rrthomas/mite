-- Utility routines for Lua scripts
-- (c) Reuben Thomas 2000

-- Give warning with, optionally, the name of program and file
function warn(s)
  if prog.name then write(_STDERR, prog.name .. ": ") end
  if file then write(_STDERR, file .. ": ") end
  write(_STDERR, s .. "\n")
end

-- Die with error
function die(s)
  warn(s)
  error()
end

-- Die with error if expression is nil
function affirm(n, s)
  if not n then die(s) end
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
