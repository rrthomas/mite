-- Mite interpreter
-- (c) Reuben Thomas 2000

return Writer{
  "Mite interpreter",
  [[
/* Interpreter state should contain:

   Registers (R array, S, P)
   Code image (two pointers)
   Label arrays
   Data image (purely to be able to free it)
   Stack (two pointers for now, eventually a linked list)
*/


#define checkDiv(d) \
  if (d == 0) \
    return ExcDivByZero;

#define checkShift(s) \
  if (s > PTR_BIT) \
    return ExcBadShift;

#define setP(x) \
  P = (x); checkP

#define checkP \
  if (P > (Word *)imgEnd || P < (Word *)img) \
    return ExcBadP;

#define setS(x) \
  S = (x); checkS

#define checkS \
  if (S > stkEnd || P < stk) \
    return ExcBadS;

/* Need a linked list of stack frames */
#define stackExtend(s) \
  return ExcBadS
#define extendS \
  if (S == stk) \
    stackExtend

#define REGS 8

Word
interp(Byte *img, Word imgSize, Byte *labAddr[LABEL_TYPES])
{
  for (;;) {
    I = *P;
    setP(P + 1);
    op = I & 0xff;
    I >>= CHAR_BIT;
  }
}
]],
  {
    Inst{"lab",    ""},
    Inst{"mov",    "R[o1] = R[o2]"},
    Inst{"movi",   "R[o1] = getNum(P, o2)"},
    Inst{"ldl",    "R[o1] = labAddr[LABEL_D][o2]"},
    Inst{"ld",     "if (R[o2] & PTR_MASK) return ExcBadAddr; " ..
                   "R[o1] = *(SWord *)R[o2]"},
    Inst{"st",     "if (R[o2] & PTR_MASK) return ExcBadAddr; " ..
                   "*(SWord *)R[o1] = R[o2]"},
    Inst{"gets",   "R[o1] = (SWord)S"},
    Inst{"sets",   "setS(R[o1])"},
    Inst{"pop",    "R[o1] = *S; setS(S + 1)"},
    Inst{"push",   "extendS; setS(S - 1); *S = R[o1]"},
    Inst{"add",    "R[o1] = R[o2] + R[o3]"},
    Inst{"sub",    "R[o1] = R[o2] - R[o3]"},
    Inst{"mul",    "R[o1] = R[o2] * R[o3]"},
    Inst{"div",    "checkDiv((Word)R[o3])"},
                   "R[o1] = (Word)R[o2] / (Word)R[o3]"},
    Inst{"rem",    "checkDiv((Word)R[o3]);" ..
                   "R[o1] = (Word)R[o2] % (Word)R[o3]"},
    Inst{"and",    "R[o1] = R[o2] & R[o3]"},
    Inst{"or",     "R[o1] = R[o2] | R[o3]"},
    Inst{"xor",    "R[o1] = R[o2] ^ R[o3]"},
    Inst{"sl",     "checkShift((Word)R[o3])"},
                   "R[o1] = R[o2] << R[o3]"},
    Inst{"srl",    "checkShift((Word)R[o3]);" ..
                   "R[o1] = (Word)R[o2] >> R[o3]"},
    Inst{"sra",    "checkShift((Word)R[o3]);" ..
                   "R[o1] = R[o2] >> R[o3]"},
    Inst{"teq",    "R[o1] = R[o2] == R[o3]"},
    Inst{"tlt",    "R[o1] = R[o2] < R[o3]"},
    Inst{"tltu",   "R[o1] = (Word)R[o2] < (Word)R[o3]"},
    Inst{"b",      "setP(o1)"},
    Inst{"br",     "setP(R[o1])"},
    Inst{"bf",     "if (!R[o1]) setP(o2)"},
    Inst{"bt",     "if (R[o1]) setP(o2)"},
    Inst{"call",   "extendS; setS(S - 1); *S = (SWord)P; " ..
                   "setP(o1 + 1)"},
    Inst{"callr",  "extendS; setS(S - 1); *S = (SWord)P; " ..
                   "setP(o1 + 1)"},
    Inst{"ret",    "if (S == stkEnd) return ExcRet; " ..
                   "setP(*S); setS(S + 1)"},
    Inst{"calln",  "(*(void (*)(void))(*(SWord *)R[o1]))()"},
  }
  Translator{"",                                 -- decls
             [[Byte op, *imgEnd = img + imgSize;
  InstWord I, *P, *S;
  SWord R[REGS], o1, o2, o3;
  Word *stk, stkSize = 1024;
  P = (Word *)img;
  stk = new(stkSize * PTR_BYTE);
  S = stk + stkSize;]],                          -- init
             "",                                 -- update
             "",                                 -- finish
  }
}
