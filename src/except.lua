exception = {
  -- fundamental errors
  Exc {"Malloc", "could not allocate memory"},
  Exc {"Realloc", "could not reallocate memory"},
  -- Mite errors
  Exc {"Ret", "ret on empty stack"},
  Exc {"BadInst", "invalid instruction"},
  Exc {"BadRegister", "invalid register"},
  Exc {"BadSize", "invalid size"},
  Exc {"BadLabel", "invalid label"},
  Exc {"BadLabelType", "invalid label type"},
  Exc {"BadArgType", "invalid argument type"},
  Exc {"BadP", "invalid P"},
  Exc {"BadS", "invalid S"},
  Exc {"BadNumber", "invalid number"},
  Exc {"BadImm", "invalid immediate"},
  Exc {"BadImmVal", "immediate value out of range"},
  Exc {"BadImmRot", "immediate rotation out of range"},
  Exc {"BadImmMod", "invalid immediate modifiers"},
  Exc {"BadAddress", "invalid address"},
  Exc {"DivByZero", "division by zero"},
  Exc {"BadShift", "invalid shift"},
  -- I/O errors
  Exc {"Fopen", "could not open `%s'"},
  Exc {"Fread", "error reading `%s'"},
  Exc {"Fwrite", "error writing `%s'"},
  Exc {"Flen", "error finding length of `%s'"},
  Exc {"EmptyFile", "empty file `%s'"},
  -- Translator errors
  Exc {"BadToken", "bad token"},
  Exc {"WrongLabel", "inconsistent label"},
  Exc {"DupLabel", "duplicate definition for `%s'"},
  -- mit errors
  Exc {"MitUsage", "Usage: %s IN-FILE [OUT-FILE]"},
  Exc {"MitBadInType", "unknown input file type `%s'"},
  Exc {"MitBadOutType", "unknown output file type `%s'"},
  Exc {"MitNoTranslator", "no translator from `%s' to `%s'"},
}
