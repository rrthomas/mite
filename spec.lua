-- Mite's specification
-- (c) Reuben Thomas 2001


-- Operand types
--   * The table is a list of types
--   * Encoding is given by list position (e.g. r = 0x1)
--   * Each type has two fields:
Type = Object{_init = {
    "name", -- as in the assembly language
    "desc", -- description
}}

opType = {
  Type{"r", "register"},
  Type{"i", "immediate constant"},
  Type{"t", "label type"},
  Type{"l", "label"},
  Type{"n", "name"},
  Type{"a", "argument type"},
  Type{"b", "return type"},
}


-- Instruction set
--   * The table is a list of instructions
--   * Opcode is given by list position (e.g. lab = 0x1)
--   * Each instruction has three fields:
Inst = Object{_init = {
    "name",   -- as in the assembly language
    "ops",    -- list of operand types (see types.lua)
    "effect", -- semantics
              -- (%n --> {ops[n]}_{n}; %% --> %; <- --> \gets)
}}

inst = {
  Inst{"lab",    {"t", "n"},       "define a type $%1$ label named $%2$"},
  Inst{"mov",    {"r", "r"},       "$%1<-%2$"},
  Inst{"movi",   {"r", "i"},       "$%1<-%2$"},
  Inst{"ldl",    {"r", "l"},       "$%1<-\\syn{d}%2$"},
  Inst{"ld",     {"r", "r"},       "$%1<-M(%2)$"},
  Inst{"st",     {"r", "r"},       "$M(%2)<-%1$"},
  Inst{"gets",   {"r"},            "$%1<-S$"},
  Inst{"sets",   {"r"},            "$S<-%1$"},
  Inst{"pop",    {"r"},            "$%1<-M(S)$; $S<-S-sw$"},
  Inst{"push",   {"r"},            "$S<-S+sw$; $M(S)<-%1$"},
  Inst{"add",    {"r", "r", "r"},  "$%1<-%2+%3$"},
  Inst{"sub",    {"r", "r", "r"},  "$%1<-%2-%3$"},
  Inst{"mul",    {"r", "r", "r"},  "$%1<-%2\\times %3$"},
  Inst{"div",    {"r", "r", "r"},  "$%1<-%2\\div %3$ (unsigned)"},
  Inst{"rem",    {"r", "r", "r"},  "$%1<-%2\\bmod %3$ (unsigned)"},
  Inst{"and",    {"r", "r", "r"},  "$%1<-%2$ bitwise and $%3$"},
  Inst{"or",     {"r", "r", "r"},  "$%1<-%2$ bitwise or $%3$"},
  Inst{"xor",    {"r", "r", "r"},  "$%1<-%2$ bitwise xor $%3$"},
  Inst{"sl",     {"r", "r", "r"},  "$%1<-%2<\\/<%3$ ($0\\leq %3\\leq 8w$)"},
  Inst{"srl",    {"r", "r", "r"},  "$%1<-%2>\\/>%3$ (logical, $0\\leq %3\\leq 8w$)"},
  Inst{"sra",    {"r", "r", "r"},  "$%1<-%2>\\/>%3$ (arithmetic, $0\\leq %3\\leq 8w$)"},
  Inst{"teq",    {"r", "r", "r"},  "$%1<-\\{%2=%3\\}$"},
  Inst{"tlt",    {"r", "r", "r"},  "$%1<-\\{%2<%3\\}$"},
  Inst{"tltu",   {"r", "r", "r"},  "$%1<-\\{%2<%3$ (unsigned)$\\}$"},
  Inst{"b",      {"l"},            "$P<-\\syn{b}%1$"},
  Inst{"br",     {"r"},            "$P<-%1$"},
  Inst{"bf",     {"r", "l"},       "if $%1=0$, $P<-\\syn{b}%2$"},
  Inst{"bt",     {"r", "l"},       "if $%1\\neq0$, $P<-\\syn{b}%2$"},
  Inst{"call",   {"l"},            "\syn{push} $P$; $P<-\\syn{s}%1$"},
  Inst{"callr",  {"r"},            "\syn{push} $P$; $P<-%1$"},
  Inst{"ret",    {},               "\syn{pop} $P$"},
  Inst{"lit",    {"i"},            "a literal word"},
  Inst{"litl",   {"t", "l"},       "a literal label"},
  Inst{"space",  {"i"},            "$%1$ zero words ($%1>0$)"},
  Inst{"func",   {"i"},            "start a function call with $%1$ arguments"},
  Inst{"funcv",  {"i"},            "start a variadic function call with $%1$ arguments"},
  Inst{"arg",    {"a", "r"},       "add argument $%2$ of type $%1$ to the current call"},
  Inst{"callf",  {"b", "l", "r"},  "\syn{push} $P$, $g_i$ ($i$ even); $P<-\\syn{f}%2$; $%3<-$ result of type $%1$"},
  Inst{"callfr", {"b", "r", "r"},  "\syn{push} $P$, $g_i$ ($i$ even); $P<-%2$; $%3<-$ result of type $%1$"},
  Inst{"retf",   {"b", "r"},       "\syn{pop} $P$, $g_i$ ($i$ even); return $%2$ of type $%1$"},
}
