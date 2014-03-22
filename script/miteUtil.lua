-- Mite-specific utility routines
-- (c) Reuben Thomas 2001


-- Global formatting parameters
width = 72 -- max width of output files
indent = 2 -- default indent

-- write a string wrapped with the above parameters, with a
-- terminating newline
function writeWrapped (s)
  io.writelines (string.wrap (s, width, indent))
end

-- produce OP_NAME from name
function opify (n)
  return "OP_" .. string.upper (n)
end
