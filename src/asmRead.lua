-- Mite assembly reader
-- (c) Reuben Thomas 2000


-- Return type for a given label operand
-- either a type variable, or determined by the instruction
function labelType(inst, op)
  local ty
  if op > 1 and inst.ops[op - 1] == "t" then
    ty = "t" .. tostring(op - 1)
  else
    local tyToNum = {
      ldl  = "LABEL_D",
      b    = "LABEL_B",
      bf   = "LABEL_B",
      bt   = "LABEL_B",
      call = "LABEL_S"
    }
    ty = tyToNum[inst.name]
  end
  return ty
end


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

static HashNode *
rdLab(TState *t, LabelType ty)
{
  char *tok;
  Label *l;
  HashLink hl;
  rdTok(t, &tok, issym);
  hashGet(t->labelHash, tok, &hl);
  if (hl.found) {
    l = hl.curr->body;
    if (l->ty != ty)
      throw("inconsistent label");
    return hl.curr;
  } else {
    l = new(Label);
    l->ty = ty;
    l->v.n = 0;
    return hashSet(t->labelHash, &hl, tok, l);
  }
}

static void
rdImm(TState *t, Byte *f, SByte *sgn, uintptr_t *v, int *r)
{
  int rsgn;
  long rl;
  char *tok, *nend;
  rdTok(t, &tok, isimm);
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
  *v = strtoul(tok, &nend, 0);
  if (errno == ERANGE || (*sgn && *v > (unsigned long)(LONG_MAX) + 1))
    /* rather than -LONG_MIN; we're assuming two's complement anyway, and
       negating LONG_MIN overflows long */
    throw("immediate value out of range");
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
    rl = strtoul(tok, &nend, 0);
    if (rl + rsgn > 127 || errno == ERANGE)
      throw("immediate rotation out of range");
    tok = nend;
    *r = rsgn ? -(int)rl : (int)rl;
  } else
    *r = 0;
  if (*tok)
    throw("bad immediate");
}

static LabelValue
labelAddr(TState *t, Label *l)
{
  LabelValue ret;
  HashLink hl;
  hashGet(t->labelHash, (char *)l->v.p, &hl);
  ret.p = hl.found ? ((Label *)hl.curr->body)->v.p : NULL;
  return ret;
}
  ]],
  "rdInst(t)",       -- rdInst(t)
  "labelAddr(t, l)", -- labelAddr(t, l)
  {
    r = OpType("Register %o = rdReg(t);", ""),
    i = OpType([[Byte %o_f;
        SByte %o_sgn;
        uintptr_t %o_v;
        int %o_r;]],
        "rdImm(t, &%o_f, &%o_sgn, &%o_v, &%o_r);"),
    t = OpType("LabelType %o = rdLabTy(t);", ""),
    l = OpType(function (inst, op)
                 local ty = labelType(inst, op)
                 return "HashNode *%o_hn = rdLab(t, " .. ty .. [[);
        LabelValue %o;]]
               end,
        "%o.p = (Byte *)%o_hn->key;"),
    n = OpType(function (inst, op)
                 local ty = labelType(inst, op)
                 return "HashNode *%o_hn = rdLab(t, " .. ty .. ");"
               end,
               function (inst, op)
                 local ty = labelType(inst, op)
                 return [[l = %o_hn->body;
        if (l->v.n)
          throw("duplicate definition for `%s'", %o_hn->key);
        l->v.n = ++t->labels[]] .. ty .. "];"
               end),
  },
  Translator(
    "Label *l;",     -- decls
    [[t->labelHash = hashNew(4096);
  t->eol = 0;]],     -- init
    "excLine += 1;", -- update
    "INST_MAXLEN"    -- maxInstLen
  )
)
