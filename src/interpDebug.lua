-- Mite interpreter debugger
-- (c) Reuben Thomas 2002

return {
  instrument = "Mite interpreter debugger",
  prelude =
[[static void
intdb_showState (objR_State *R, runW_State *W, Word *S, SWord r[REGS])
{
  int i;
  for (i = 0; i < REGS; i++) {
    debug ("P = %p\n", R->ptr);
    debug ("S = %p\n", S);
    debug ("r[%d] = %d\n", i, r[i]);
  }
}]],
  macros =
[[#define i(i) debug (#i)
#define r(r) debug ("%d ", r)
#define labTy(t) debug ("%c ", labTyToChar (t))
#define lab(l) \
  { \
    char *s = excMalloc (sizeof (char) * WORD_MAXLEN); \
    s[writeNum (s, l)] = '\0'; \
    debug ("%s ", s); \
    free (s); \
  }
#define imm(f, n, v, r) \
  { \
    char *s = excMalloc (sizeof (char) * IMM_MAXLEN); \
    s[writeImm (s, f, n, v, r)] = '\0'; \
    debug ("%s ", s); \
    free (s); \
  }]],
  inst = {
    Inst {"lab",    "i (lab); labTy (t1)"},
    Inst {"mov",    "i (mov); r (r1); r (r2)"},
    Inst {"movi",   "i (movi); r (r1); " ..
                    "imm (i2_f, i2_sgn, i2_v, i2_r)"},
    Inst {"ldl",    "i (ldl); r (r1); labTy (LABEL_D); lab (l2.n)"},
    Inst {"ld",     "i (ld); r (r1); r (r2)"},
    Inst {"st",     "i (st); r (r1); r (r2)"},
    Inst {"gets",   "i (gets); r (r1)"},
    Inst {"sets",   "i (sets); r (r1)"},
    Inst {"pop",    "i (pop); r (r1)"},
    Inst {"push",   "i (push); r (r1)"},
    Inst {"add",    "i (add); r (r1); r (r2); r (r3)"},
    Inst {"sub",    "i (sub); r (r1); r (r2); r (r3)"},
    Inst {"mul",    "i (mul); r (r1); r (r2); r (r3)"},
    Inst {"div",    "i (div); r (r1); r (r2); r (r3)"},
    Inst {"rem",    "i (rem); r (r1); r (r2); r (r3)"},
    Inst {"and",    "i (and); r (r1); r (r2); r (r3)"},
    Inst {"or",     "i (or); r (r1); r (r2); r (r3)"},
    Inst {"xor",    "i (xor); r (r1); r (r2); r (r3)"},
    Inst {"sl",     "i (sl); r (r1); r (r2); r (r3)"},
    Inst {"srl",    "i (srl); r (r1); r (r2); r (r3)"},
    Inst {"sra",    "i (sra); r (r1); r (r2); r (r3)"},
    Inst {"teq",    "i (teq); r (r1); r (r2); r (r3)"},
    Inst {"tlt",    "i (tlt); r (r1); r (r2); r (r3)"},
    Inst {"tltu",   "i (tltu); r (r1); r (r2); r (r3)"},
    Inst {"b",      "i (b); labTy (LABEL_B); lab (l1.n)"},
    Inst {"br",     "i (br); r (r1)"},
    Inst {"bf",     "i (bf); r (r1); labTy (LABEL_B); lab (l2.n)"},
    Inst {"bt",     "i (bt); r (r1); labTy (LABEL_B); lab (l2.n)"},
    Inst {"call",   "i (call); labTy (LABEL_S); lab (l1.n)"},
    Inst {"callr",  "i (callr); r (r1)"},
    Inst {"ret",    "i (ret)"},
    Inst {"calln",  "i (calln); r (r1)"},
    Inst {"lit",    "i (lit); imm (i1_f, i1_sgn, i1_v, i1_r)"},
    Inst {"litl",   "i (litl); labTy (t1); lab (l2.n)"},
    Inst {"space",  "i (space); imm (i1_f, i1_sgn, i1_v, i1_r)"},
  },
  trans = Translator {
             "",                                -- decls
             "",                                -- init
             "intdb_showState (R, W, S, r);",   -- update
             "",                                -- finish
  },
}
