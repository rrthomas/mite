-- Mite-specific utility routines
-- (c) Reuben Thomas 2001


-- produce OP_NAME from name
function opify(n)
  return "OP_" .. strupper(n)
end
