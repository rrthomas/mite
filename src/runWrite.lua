-- Mite interpreter
-- (c) Reuben Thomas 2000

return {
  writes = "Mite interpreter",
  output =
[[/* Interpreter output */
typedef struct {
  Word ret;
} runW_Output;
]],
  prelude = [[
typedef void runW_State;

#define returnWith(r) \
  out->ret = r; \
  return out

#define checkDiv(d) \
  if (d == 0) \
    returnWith (ExcDivByZero)

#define checkShift(s) \
  if (s > WORD_BIT) \
    returnWith (ExcBadShift)

#define P R->ptr
    
#define setP(x) \
  P = (Byte *)(x); checkP

#define checkP \
  if (P > R->end || P < R->img) \
    returnWith (ExcBadP)

#define setS(x) \
  S = (Word *)(x); checkS

#define checkS \
  if (S > stkEnd || S < stk) \
    returnWith (ExcBadS)

/* TODO: Use a linked list of stack frames; setS will unwind it */
#define stackExtend \
  returnWith (ExcBadS)
#define extendS \
  if (S == stk) \
    stackExtend

#define REGS 8

static void *
runW_writerNew (void)
{
  return NULL;
}
]],
  resolve = nil,
  macros = "",
  inst = {
    Inst {"lab",    ""},
    Inst {"mov",    "r[o1] = r[o2]"},
    Inst {"movi",   "r[o1] = objR_getNum (R, &o2)"},
    Inst {"ldl",    "r[o1] = inp->labAddr[LABEL_D][o2]"},
    Inst {"ld",     "if (r[o2] & WORD_MASK) returnWith (ExcBadAddr); " ..
                   "r[o1] = *(SWord *)r[o2]"},
    Inst {"st",     "if (r[o2] & WORD_MASK) returnWith (ExcBadAddr); " ..
                   "*(SWord *)r[o1] = r[o2]"},
    Inst {"gets",   "r[o1] = (SWord)S"},
    Inst {"sets",   "setS (r[o1])"},
    Inst {"pop",    "r[o1] = *S; setS (S + 1)"},
    Inst {"push",   "extendS; setS (S - 1); *S = r[o1]"},
    Inst {"add",    "r[o1] = r[o2] + r[o3]"},
    Inst {"sub",    "r[o1] = r[o2] - r[o3]"},
    Inst {"mul",    "r[o1] = r[o2] * r[o3]"},
    Inst {"div",    "checkDiv ((Word)r[o3]); " ..
                   "r[o1] = (Word)r[o2] / (Word)r[o3]"},
    Inst {"rem",    "checkDiv ((Word)r[o3]); " ..
                   "r[o1] = (Word)r[o2] % (Word)r[o3]"},
    Inst {"and",    "r[o1] = r[o2] & r[o3]"},
    Inst {"or",     "r[o1] = r[o2] | r[o3]"},
    Inst {"xor",    "r[o1] = r[o2] ^ r[o3]"},
    Inst {"sl",     "checkShift ((Word)r[o3]); " ..
                   "r[o1] = r[o2] << r[o3]"},
    Inst {"srl",    "checkShift ((Word)r[o3]); " ..
                   "r[o1] = (Word)r[o2] >> r[o3]"},
    Inst {"sra",    "checkShift ((Word)r[o3]); " ..
                   "r[o1] = r[o2] >> r[o3]"},
    Inst {"teq",    "r[o1] = r[o2] == r[o3]"},
    Inst {"tlt",    "r[o1] = r[o2] < r[o3]"},
    Inst {"tltu",   "r[o1] = (Word)r[o2] < (Word)r[o3]"},
    Inst {"b",      "setP (o1)"},
    Inst {"br",     "setP (r[o1])"},
    Inst {"bf",     "if (!r[o1]) setP (o2)"},
    Inst {"bt",     "if (r[o1]) setP (o2)"},
    Inst {"call",   "extendS; setS (S - 1); *S = (SWord)P; " ..
                   "setP (o1 + 1)"},
    Inst {"callr",  "extendS; setS (S - 1); *S = (SWord)P; " ..
                   "setP (o1 + 1)"},
    Inst {"ret",    "if (S == stkEnd) returnWith (ExcRet); " ..
                   "setP (*S); setS (S + 1)"},
    Inst {"calln",  "(*(void (*)(void))(*(SWord *)r[o1]))()"},
    Inst {"lit",    ""},
    Inst {"litl",  ""},
    Inst {"space", ""},
  },
  trans = Translator {
    [[SWord r[REGS], o1, o2, o3;
  Word *S, *stk, *stkEnd, stkSize = 1024;
]],                                      -- decls
    [[stk = new (stkSize * WORD_BYTE);
  stkEnd = S = stk + stkSize;]],         -- init
    "",                                  -- update
    "",                                  -- finish
  },
}
