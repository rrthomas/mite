-- Mite assembly reader
-- (c) Reuben Thomas 2000


-- Return type for a given label operand
-- either a type variable, or determined by the instruction
function labelType (inst, op)
  if op > 1 and inst.ops[op - 1] == "t" then
    return "t" .. tostring (op - 1)
  else
    local tyToNum = {
      ldl  = "LABEL_D",
      b    = "LABEL_B",
      bf   = "LABEL_B",
      bt   = "LABEL_B",
      call = "LABEL_S"
    }
    return tyToNum[inst.name]
  end
end


return {
  reads = "Mite assembly",
  input =
  [[/* Assembly reader input */
typedef struct {
  char *img;
  size_t size;
} asmR_Input;
]],
  prelude =
[[#include <stdint.h>
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <string.h>


/* Assembly reader state */
typedef struct {
  char *img;
  char *end;
  char *ptr;
  Hash *labHash; /* table of label names */
  Bool eol; /* EOL state */
} asmR_State;

static int
issym (int c)
{
  return isalnum (c) || (c == '_');
}

static int
isimm (int c)
{
  return isxdigit (c) || strchr (">-_swx", c);
}

/* Read next token consisting of characters for which f () returns true
   into *tok, advancing R->ptr past it, and discarding leading non-f ()
   characters and comments */
static Word
asmR_tok (asmR_State *R, char **tok, int (*f)(int))
{ 
#define p R->ptr
  if (R->eol) {
    excPos++;
    R->eol = 0;
  }
  while (*p && (isspace ((char)*p) || (char)*p == '#')) {
    if ((char)*p == '#')
      do {
        p++;
      } while (*p && (char)*p != '\n');
    if ((char)*p == '\n')
      excPos++;
    p++;
  }
  *tok = (char *)p;
  while (f ((char)*p)) p++;
  if (*tok == (char *)p)
    die (ExcMissingTok);
  if (!isspace ((char)*p))
    die (ExcBadChar);
  if ((char)*p == '\n')
    R->eol = 1;
  *p = '\0';
  return p++ - *tok;
#undef p
}

static Opcode
rdInst (asmR_State *R)
{
  char *tok;
  Word len = asmR_tok (R, &tok, issym);
  struct Inst *i = findInst (tok, len);
  if (i == NULL)
    die (ExcBadInst);
  return i->opcode;
}

#undef isdigit /* use the function, not the macro */
static Register
rdReg (asmR_State *R)
{
  char *tok, *nend;
  Register r;
  Word len = asmR_tok (R, &tok, isdigit);
  r = strtoul (tok, &nend, 10);
  if (r > UINT_MAX || (Word)(nend - tok) != len)
    die (ExcBadReg);
  return r;
}

static LabelType
asmR_labTy (asmR_State *R)
{
  char *tok;
  Word len = asmR_tok (R, &tok, isalpha);
  if (len == 1)
    switch (*tok) {
    case 'b':
      return LABEL_B;
    case 's':
      return LABEL_S;
    case 'd':
      return LABEL_D;
    }
  die (ExcBadLabTy);
}

static List *
asmR_lab (asmR_State *R, LabelType ty)
{
  char *tok;
  Label *l;
  List *hp;
  uint32_t hEntry;
  asmR_tok (R, &tok, issym);
  hp = hashGet (R->labHash, tok, &hEntry);
  if (hp) {
    l = hp->body;
    if (l->ty != ty)
      die (ExcWrongLab);
    return hp;
  } else {
    l = new (Label);
    l->ty = ty;
    l->v.n = 0;
    return hashSet (R->labHash, hp, hEntry, tok, l);
  }
}

static void
asmR_imm (asmR_State *R, Byte *f, SByte *sgn, int *r, Word *v)
{
  int rsgn;
  long rl;
  char *tok, *nend;
  asmR_tok (R, &tok, isimm);
  *f = 0;
  if (*tok == 'e') {
    tok++;
    *f |= FLAG_E;
  }
  if (*tok == 's') {
    tok++;
    *f |= FLAG_S;
  }
  if (*tok == 'w') {
    tok++;
    *f |= FLAG_W;
  }
  if (*tok == '-') {
    tok++;
    *sgn = 1;
  } else
    *sgn = 0;
  errno = 0;
  *v = strtoul (tok, &nend, 0);
  if (errno == ERANGE || (*sgn && *v > (unsigned long)(LONG_MAX) + 1))
    /* rather than -LONG_MIN; we're assuming two's complement anyway,
       and negating LONG_MIN overflows long */
    die (ExcBadImmVal);
  tok = nend;
  rsgn = 0;
  if (*tok == '>' && tok[1] == '>') {
    tok += 2;
    *f |= FLAG_R;
    errno = 0;
    if (*tok == '-') {
	tok++;
	rsgn = -1;
    }
    rl = strtoul (tok, &nend, 0);
    if (rl + rsgn > 127 || errno == ERANGE)
      die (ExcBadImmRot);
    tok = nend;
    *r = rsgn ? -(int)rl : (int)rl;
  } else
    *r = 0;
  if (*tok)
    die (ExcBadImm);
}

static LabelValue
asmR_labelAddr (asmR_State *R, Label *l)
{
  LabelValue ret;
  List *hp;
  uint32_t hEntry;
  hp = hashGet (R->labHash, (char *)l->v.p, &hEntry);
  ret.p = (hp != NULL) ? ((Label *)hp->body)->v.p : NULL;
  return ret;
}

static asmR_State *
asmR_readerNew (asmR_Input *inp)
{
  asmR_State *R = new (asmR_State);
  R->ptr = R->img = inp->img;
  R->end = inp->img + inp->size;
  return R;
}
]],
  opType = {
    r = OpType {"Register r%n = rdReg (R);", ""},
    i = OpType {[[Byte i%n_f;
        SByte i%n_sgn;
        int i%n_r;
        Word i%n_v;]],
        "asmR_imm (R, &i%n_f, &i%n_sgn, &i%n_r, &i%n_v);"},
    t = OpType {"LabelType t%n = asmR_labTy (R);", ""},
    l = OpType {function (inst, op)
                  local ty = labelType (inst, op)
                  return "List *l%n_l = asmR_lab (R, " .. ty .. [[);
        LabelValue l%n;]]
                end,
        "l%n.p = l%n_l->key;"},
    n = OpType {function (inst, op)
                  local ty = labelType (inst, op)
                  return "List *n%n_l = asmR_lab (R, " .. ty ..
                    ");\n        Label *l;"
                end,
                function (inst, op)
                  local ty = labelType (inst, op)
                  return [[l = n%n_l->body;
        if (l->v.n)
          die (ExcDupLab, n%n_l->key);
        l->v.n = ++T->labels[]] .. ty .. "];"
                end},
  },
  trans = Translator {
    "",                              -- decls
    [[R->labHash = hashNew (4096);
  R->eol = 0;]],                     -- init
    "o = rdInst (R);",               -- update
    "",                              -- finish
  },
}
