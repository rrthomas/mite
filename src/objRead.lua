-- Mite assembly reader
-- (c) Reuben Thomas 2000

return Reader(
  "Mite assembly",
  [[
#include <stdint.h>
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <string.h>

#include "except.h"
#include "hash.h"
#include "string.h"
#include "translate.h"


static int
issym(int c)
{
  return isalnum(c) || (c == '_');
}

static int
isimm(int c)
{
  return isxdigit(c) || strchr(">-_swx", c);
}

/* Read next token consisting of characters for which f() returns true into
   *tok, advancing t->rPtr past it, and discarding leading non-f() characters
   and comments */
static uintptr_t
rdTok(TState *t, char **tok, int (*f)(int))
{ 
#define p t->rPtr
  if (t->eol) {
    excLine++;
    t->eol = 0;
  }
  while (*p && (isspace((char)*p) || (char)*p == '#')) {
    if ((char)*p == '#')
      do {
        p++;
      } while (*p && (char)*p != '\n');
    if ((char)*p == '\n')
      excLine++;
    p++;
  }
  *tok = (char *)p;
  while (f((char)*p)) p++;
  if (*tok == (char *)p)
    throw("missing token");
  if (!isspace((char)*p))
    throw("bad character");
  if ((char)*p == '\n')
    t->eol = 1;
  *p = (Byte)'\0';
  return p++ - (Byte *)*tok;
#undef p
}

static Opcode
rdInst(TState *t)
{
  char *tok;
  uintptr_t len = rdTok(t, &tok, issym);
  struct Inst *i = findInst(tok, len);
  if (i == NULL)
    throw("bad instruction");
  return i->opcode;
}

#undef isdigit /* use the function, not the macro */
static Register
rdReg(TState *t)
{
  char *tok, *nend;
  Register r;
  uintptr_t len = rdTok(t, &tok, isdigit);
  r = strtoul(tok, &nend, 10);
  if (r > UINT_MAX || (uintptr_t)(nend - tok) != len)
    throw("bad register");
  return r;
}

static LabelType
rdLabTy(TState *t)
{
  char *tok;
  uintptr_t len = rdTok(t, &tok, isalpha);
  if (len == 1)
    switch (*tok) {
    case 'b':
      return LABEL_B;
    case 's':
      return LABEL_S;
    case 'd':
      return LABEL_D;
    }
  throw("bad label type");
}

static Label *
rdLab(TState *t, LabelType ty)
{
  Label *l = new(Label);
  l->ty = ty;
  rdTok(t, (char **)&l->v.p, issym);
  return l;
}

static Immediate
rdImm(TState *t)
{
  Immediate *i = new(Immediate);
  int rsgn;
  long rl;
  char *tok, *nend;
  rdTok(t, &tok, isimm);
  i->f = 0;
  if (*tok == 'e') {
    tok++;
    i->f |= FLAG_E;
  }
  if (*tok == 's') {
    tok++;
    i->f |= FLAG_S;
  }
  if (*tok == 'w') {
    tok++;
    i->f |= FLAG_W;
  }
  if (*tok == '-') {
    tok++;
    i->sgn = 1;
  } else
    i->sgn = 0;
  errno = 0;
  i->v = strtoul(tok, &nend, 0);
  if (errno == ERANGE || (i->sgn && i->v > (unsigned long)(LONG_MAX) + 1))
    /* rather than -LONG_MIN; we're assuming two's complement anyway, and
       negating LONG_MIN overflows long */
    throw("immediate value out of range");
  tok = nend;
  rsgn = 0;
  if (*tok == '>' && tok[1] == '>') {
    tok += 2;
    i->f |= FLAG_R;
    errno = 0;
    if (*tok == '-') {
	tok++;
	rsgn = -1;
    }
    rl = strtoul(tok, &nend, 0);
    if (rl + rsgn > 127 || errno == ERANGE)
      throw("immediate rotation out of range");
    tok = nend;
    i->r = rsgn ? -(int)rl : (int)rl;
  } else
    i->r = 0;
  if (*tok)
    throw("bad immediate");
  return i;
}

static LabelValue
labelAddr(TState *t, Label *l)
{
  LabelValue ret;
  ret.p = hashFind(t->labelHash, l->v.p);
  return ret;
}
  ]],
  "rdInst(t)", -- rdInst(t)
  "labelMap(t, l)", -- labelMap(t, l)
  {
    OpType("r", "Register", "rdReg(t)"),
    OpType("i", "Immediate", "rdImm(t)"),
    OpType("t", "Label", "rdLab(t, rdLabTy(t))"),
    OpType("l", "", ""),
    OpType("n", "", -- relies on n always being in position 2
           [[t->labels[t1->ty]++;
      if ((old = hashFind(t->labelHash, t1->v.p))) {
        if (old->ty != t1->ty)
          throw("inconsistent label");
      } else
        hashInsert(t->labelHash, t1->v.p,
                   (void *)(t->labels[t1->ty]))]]),
  },
  {
    "Label *old;", -- decls
    [[t->labelHash = hashNew(4096, hashStrHash, hashStrcmp);
      t->eol = 0;]], -- init
    "excLine += 1;", -- updateExcLine
    "INST_MAXLEN", -- maxInstLen
  }
)
