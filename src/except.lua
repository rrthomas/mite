Exc = constructor{
  "name",
  "message", -- printed when throw reaches the top level
}

exception = {
  -- fundamental errors
  Exc{"Malloc", "could not allocate memory"},
  Exc{"Realloc", "could not reallocate memory"},
  -- Mite errors
  Exc{"Ret", "ret on empty stack"},
  Exc{"BadInst", "invalid instruction"},
  Exc{"BadReg", "invalid register"},
  Exc{"BadLab", "invalid label"},
  Exc{"BadLabTy", "invalid label type"},
  Exc{"BadP", "invalid P"},
  Exc{"BadS", "invalid S"},
  Exc{"BadImm", "invalid immediate"},
  Exc{"BadImmVal", "immediate value out of range"},
  Exc{"BadImmRot", "immediate rotation out of range"},
  Exc{"BadImmMod", "invalid immediate modifiers"},
  Exc{"BadAddr", "invalid address"},
  Exc{"DivZero", "division by zero"},
  Exc{"BadShift", "invalid shift"},
  -- I/O errors
  Exc{"Fopen", "could not open `%s'"},
  Exc{"Fread", "error reading `%s'"},
  Exc{"Fwrite", "error writing `%s'"},
  Exc{"Flen", "error finding length of `%s'"},
  Exc{"EmptyFile", "empty file `%s'"},
  -- Translator errors
  Exc{"MissingTok", "missing token"},
  Exc{"BadChar", "invalid character"},
  Exc{"WrongLab", "inconsistent label"},
  Exc{"DupLab", "duplicate definition for `%s'"}
}
