-- Mite's specification
-- (c) Reuben Thomas 2001


-- Operand types
--   * The table is a list of types
--   * Encoding is given by list position (e.g. r = 0x1)
--   * Each type has two fields:
Type = constructor{
  "name", -- as in the assembly language
  "desc", -- informal description
}

type = {
  Type("r",    "register"),
  Type("i",    "immediate constant"),
  Type("l",    "label (any type)"),
  Type("L",    "label definition"),
  Type("b",    "branch label"),
  Type("s",    "subroutine label"),
  Type("d",    "data label"),
}


-- Instruction set
--   * The table is a list of instructions
--   * Opcode is given by list position (e.g. lab = 0x1)
--   * Each instruction has three fields:
Inst = constructor{
  "name", -- as in the assembly language
  "ops",  -- list of operand types (see types.lua)
  "desc", -- informal semantics
          -- (%n --> {ops[n]}_{n}; %% --> %; <- --> \gets)
}

inst = {
  Inst("lab",    {"L"},            "define a label"),
  Inst("mov",    {"r", "r"},       "$%1<-%2$"),
  Inst("movi",   {"r", "i"},       "$%1<-%2$"),
  Inst("ldl",    {"r", "d"},       "$%1<-%2$"),
  Inst("ld",     {"r", "r"},       "$%1<-M(%2)$"),
  Inst("st",     {"r", "r"},       "$M(%2)<-%1$"),
  Inst("gets",   {"r"},            "$%1<-S$"),
  Inst("sets",   {"r"},            "$S<-%1$"),
  Inst("pop",    {"r"},            "$%1<-M(S)$; $S<-S-sw$"),
  Inst("push",   {"r"},            "$S<-S+sw$; $M(S)<-%1$"),
  Inst("add",    {"r", "r", "r"},  "$%1<-%2+%3$"),
  Inst("sub",    {"r", "r", "r"},  "$%1<-%2-%3$"),
  Inst("mul",    {"r", "r", "r"},  "$%1<-%2\\times %3$"),
  Inst("div",    {"r", "r", "r"},  "$%1<-%2\\div %3$ (unsigned)"),
  Inst("rem",    {"r", "r", "r"},  "$%1<-%2\\bmod %3$ (unsigned)"),
  Inst("and",    {"r", "r", "r"},  "$%1<-%2$ bitwise and $%3$"),
  Inst("or",     {"r", "r", "r"},  "$%1<-%2$ bitwise or $%3$"),
  Inst("xor",    {"r", "r", "r"},  "$%1<-%2$ bitwise xor $%3$"),
  Inst("sl",     {"r", "r", "r"},  "$%1<-%2<\\/<%3$ ($0\\leq %3\\leq 8w$)"),
  Inst("srl",    {"r", "r", "r"},  "$%1<-%2>\\/>%3$ (logical, $0\\leq %3\\leq 8w$)"),
  Inst("sra",    {"r", "r", "r"},  "$%1<-%2>\\/>%3$ (arithmetic, $0\\leq %3\\leq 8w$)"),
  Inst("teq",    {"r", "r", "r"},  "$%1<-\\{%2=%3\\}$"),
  Inst("tlt",    {"r", "r", "r"},  "$%1<-\\{%2<%3\\}$"),
  Inst("tltu",   {"r", "r", "r"},  "$%1<-\\{%2<%3$ (unsigned)$\\}$"),
  Inst("b",      {"b"},            "$P<-%1$"),
  Inst("br",     {"r"},            "$P<-%1$"),
  Inst("bf",     {"r", "b"},       "if $%1=0$, $P<-%2$"),
  Inst("bt",     {"r", "b"},       "if $%1\\neq0$, $P<-%2$"),
  Inst("call",   {"s"},            "$S<-S+sw$; $M(S)<-P$; $P<-%1$"),
  Inst("callr",  {"r"},            "$S<-S+sw$; $M(S)<-P$; $P<-%1$"),
  Inst("ret",    {},               "$P<-M(S)$; $S<-S-sw$"),
  Inst("calln",  {"r"},            "call native code at $%1$"),
  Inst("lit",    {"i"},            "a literal word"),
  Inst("litl",   {"l"},            "a literal label"),
  Inst("space",  {"i"},            "$%1$ zero words ($%1>0$)"),
}
