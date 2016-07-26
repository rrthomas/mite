-- Mite's specification
-- (c) Reuben Thomas 2001


-- Operand types
--   * The table is a list of types
--   * Encoding is given by list position (e.g. r = 0x1)
--   * Each type has two fields:
Type = Object {_init = {
    "name", -- as in the assembly language
    "desc", -- description
}}

opType = {
  Type {"r", "integer register"},
  Type {"R", "integer register, \\syn{S} or \\syn{F}"},
  Type {"s", "size"},
  Type {"i", "immediate constant"},
  Type {"n", "immediate number"},
  Type {"t", "label type"},
  Type {"l", "label"},
  Type {"x", "name"},
  Type {"a", "argument type"},
}


-- Instruction set
--   * The table is a list of instructions
--   * Opcode is given by list position (e.g. lab = 0x1)
--   * Each instruction has three fields:
Inst = Object{_init = {
    "name",   -- as in the assembly language
    "ops",    -- list of operand types (see above)
    "effect", -- semantics
              -- (%n --> {ops[n]}_{n}; %% --> %; <- --> \gets)
}}

inst = {
  Inst {"lab",     {"t", "x"},            "define a type $%1$ label named $%2$"},
  Inst {"mov",     {"R", "R"},            "$%1<-%2$"},
  Inst {"movi",    {"r", "i"},            "$%1<-%2$"},
  Inst {"ldl",     {"r", "l"},            "$%1<-\\syn{d}%2$"},
  Inst {"ld",      {"s", "r", "r"},       "$%2<-M_{%1}(%3)$"},
  Inst {"st",      {"s", "r", "r"},       "$M(%3)_{%1}<-%2$"},
  Inst {"add",     {"r", "r", "r"},       "$%1<-%2+%3$"},
  Inst {"sub",     {"r", "r", "r"},       "$%1<-%2-%3$"},
  Inst {"mul",     {"r", "r", "r"},       "$%1<-%2\\times %3$"},
  Inst {"div",     {"r", "r", "r"},       "$%1<-%2\\div %3$ (unsigned)"},
  Inst {"rem",     {"r", "r", "r"},       "$%1<-%2\\bmod %3$ (unsigned)"},
  Inst {"and",     {"r", "r", "r"},       "$%1<-%2$ bitwise and $%3$"},
  Inst {"or",      {"r", "r", "r"},       "$%1<-%2$ bitwise or $%3$"},
  Inst {"xor",     {"r", "r", "r"},       "$%1<-%2$ bitwise xor $%3$"},
  Inst {"sl",      {"r", "r", "r"},       "$%1<-%2<\\/<%3$ ($0\\leq %3\\leq 8w$)"},
  Inst {"srl",     {"r", "r", "r"},       "$%1<-%2>\\/>%3$ (logical, $0\\leq %3\\leq 8w$)"},
  Inst {"sra",     {"r", "r", "r"},       "$%1<-%2>\\/>%3$ (arithmetic, $0\\leq %3\\leq 8w$)"},
  Inst {"teq",     {"r", "r", "r"},       "$%1<-\\{%2=%3\\}$"},
  Inst {"tlt",     {"r", "r", "r"},       "$%1<-\\{%2<%3\\}$"},
  Inst {"tltu",    {"r", "r", "r"},       "$%1<-\\{%2<%3$ (unsigned)$\\}$"},
  Inst {"b",       {"l"},                 "$\\syn{P}<-\\syn{b}%1$"},
  Inst {"br",      {"r"},                 "$\\syn{P}<-%1$"},
  Inst {"bf",      {"r", "l"},            "if $%1=0$, $\\syn{P}<-\\syn{b}%2$"},
  Inst {"call",    {"l"},                 "push \\syn{P}; $\\syn{P}<-\\syn{s}%1$"},
  Inst {"callr",   {"r"},                 "push \\syn{P}; $\\syn{P}<-%1$"},
  Inst {"ret",     {},                    "pop \\syn{P}"},
  Inst {"salloc",  {"r"},                 "$\\syn{S}<-\\rho$; $\\syn{F}<-\\rho$; $\\syn{F}-\\syn{S}S\\geq %1W$"},
  -- FIXME: Extend semantics of lit to replace space: repeat the last literal up to the number required
  Inst {"lit",     {"s", "n", "i+"},      "$%2$ $%1$-byte literals $%3$"},
  Inst {"litl",    {"t", "l"},            "a literal label"},
  -- Inst {"func",    {"i"},                 "start a function call with $%1$ arguments"},
  -- Inst {"funcv",   {"i"},                 "start a variadic function call with $%1$ arguments"},
  -- Inst {"arg",     {"r", "a"},            "add argument $%1$ of type $%2$ to the current call"},
  -- Inst {"callf",   {"l"},                 "push \\syn{P}, $g_i$ ($i$ even); $\\syn{P}<-\\syn{f}%1$"},
  -- Inst {"callfr",  {"r"},                 "push \\syn{P}, $g_i$ ($i$ even); $\\syn{P}<-%1$"},
  -- Inst {"callfn",  {"r"},                 "push \\syn{P}, $g_i$ ($i$ even); call native function at $%1$"},
  -- Inst {"getret",  {"r", "a"},            "$%1<-\\syn{T}$ of type $%2$"},
  -- Inst {"retf",    {"r", "a"},            "pop \\syn{P}, $g_i$ ($i$ even); $\\syn{T}<-%1$ of type $%2$"},
  -- Inst {"retf0",   {},                    "pop \\syn{P}, $g_i$ ($i$ even)"},
}
