/* Mite assembly to Mite object translator */


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
  
#define rdInst(t) rdInst(t)
#define labelAddr(t, l) labelMap(t, l)


#include <stdint.h>
#include <limits.h>

#include "endian.h"
#include "except.h"
#include "translate.h"


/* Store w in the rest of the current instruction word in big-endian
   order; the data given in w must fit in p mod WORD_BYTE bytes */
static void
writeBytes(Byte *p, uint32_t w)
{
  int i = WORD_BYTES_LEFT(p) - 1;
  do {
    p[i--] = (Byte)w; /* Check this cast works as expected */
    w >>= BYTE_BIT;
  } while (i >= 0);
}

/* Write an integer: sgn is 0 for +ve, 1 for -ve; n is the value */
static uintptr_t
writeInt(Byte *p, int sgn, uintptr_t n)
{
  int len = 1, cur = (WORD_BYTES_LEFT(p) << BYTE_SHIFT) - 1;
  uintptr_t bytes = 0;
  while (n >> len && len < (int)WORD_BIT)
    len++;
  if (sgn)
    n = (uintptr_t)(-(intptr_t)n);
  while ((bytes += (cur + 1) >> BYTE_SHIFT), len > cur) {
    len -= cur; /* Number of bits left */
    writeBytes(p, (uint32_t)(n >> len));
    cur = WORD_BIT - 1;
  }
  writeBytes(p, (uint32_t)(n & ((1 << cur) - 1)) /* Mask cur bits */
	     | (1 << cur)); /* Add 1 bit to last word */
  return bytes;
}

#define NUM_MAX_LENGTH PTR_BYTE + WORD_BYTE

#define B(b) \
  *t->wPtr++ = (Byte)b

#ifdef LITTLE_ENDIAN
#  define W(a, b, c, d) \
     *(Word *)t->wPtr = a | (b << BYTE_BIT) | \
       (c << (BYTE_BIT * 2)) | (d << (BYTE_BIT * 3)); \
     t->wPtr += WORD_BYTE
#else /* !LITTLE_ENDIAN */
#  define W(a, b, c, d) \
     *(Word *)t->wPtr = (a << (BYTE_BIT * 3)) | \
       (b << (BYTE_BIT * 2)) | (c << BYTE_BIT) | d; \
     t->wPtr += WORD_BYTE
#endif /* LITTLE_ENDIAN */

#define Lab(ty, l) \
  addDangle(t, ty, l); \
  align(t)

#define Imm(f, n, v, r) \
  *t->wPtr++ = (Byte)(f); \
  if (r) \
    *t->wPtr++ = (Byte)r; \
  putInt(t, n, v)

#define putInt(t, sgn, n) \
  t->wPtr += writeInt(t->wPtr, sgn, n)

#define putUInt(t, n) \
  putInt(t, 0, n)

static uintptr_t
writeUInt(Byte **p, uintptr_t n)
{
  uintptr_t len = writeInt(*p, 0, n);
  *p += len;
  return len & WORD_ALIGN;
}
  
#define DANGLE_MAXLEN (WORD_BYTE * 2)
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL


