-- Mite interpretive code reader
-- (c) Reuben Thomas 2002

-- This is just the object code writer with a different input type

r = dofile "objRead.lua"
r.input = [[/* Interpreter input */
typedef interpW_Output interpR_Input;
]]

return r
