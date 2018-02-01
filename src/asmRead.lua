-- Mite assembly reader
-- (c) Reuben Thomas 2000


-- Return type for a given label operand
-- either a type variable, or determined by the instruction
function labelType (inst, op)
  if op > 1 and inst.ops[op - 1] == "t" then
    return "t" .. tostring(op - 1)
  else
    local tyToNum = {
      ldl    = "LABEL_D",
      b      = "LABEL_B",
      bf     = "LABEL_B",
      bt     = "LABEL_B",
      call   = "LABEL_S",
      callf  = "LABEL_F",
    }
    return tyToNum[inst.name]
  end
end

OpType =
  function (arg)
    local decl, code = arg[1], arg[2]
    -- decl: declarations for the operand reading code
    -- code: code to read an operand of the given type
    -- each is either a string, or a function (inst, op) ->
    -- string
    -- in the output, %n -> operand no.
    function funcify (f)
      if type (f) ~= "function" then
        local _f = f
        f = function (inst, op)
          return _f
        end
      end
      return function (inst, opNo)
        local s = f (inst, opNo)
        return string.gsub (s, "%%n", tostring (opNo))
      end
    end
    local t = {decl = funcify (decl), code = funcify (code)}
    return t
  end

local r = {
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
asmR_isSym(int c)
{
  return isalnum(c) || (c == '_');
}

static int
asmR_isImm(int c)
{
  return isxdigit(c) || strchr(">-_swx", c);
}

/* Discard leading white space and comments */
static void
asmR_skipSpace(asmR_State *R)
{ 
#define p R->ptr
  if (R->eol) {
    excPos++;
    R->eol = 0;
  }
  while (*p && (isspace((char)*p) || (char)*p == '#')) {
    if ((char)*p == '#')
      do {
        p++;
      } while (*p && (char)*p != '\n');
    if ((char)*p == '\n')
      excPos++;
    p++;
  }
#undef p
}

/* Read next token consisting of characters for which f() returns
   true, advancing R->ptr past it, and discarding leading white
   space characters and comments; return pointer to token in *tok, and
   length of token as return value*/
static Word
asmR_tok(asmR_State *R, char **tok, int (*f)(int))
{ 
#define p R->ptr
  asmR_skipSpace(R);
  *tok = (char *)p;
  while (f((char)*p))
    p++;
  if (*tok == (char *)p || (!isspace((char)*p) && *p != '\0'))
    die(ExcBadToken);
  else if ((char)*p == '\n')
    R->eol = 1;
  *p = '\0';
  return p++ - *tok;
#undef p
}

/* From now on, make sure the following are functions, not macros */
#undef isdigit
#undef isalpha
#undef isalnum

static Opcode
asmR_inst(asmR_State *R)
{
  char *tok;
  struct Inst *i;
  Word len = asmR_tok(R, &tok, asmR_isSym);
  i = findInst(tok, len);
  if (i == NULL)
    die(ExcBadInst);
  return i->opcode;
}

static Word
asmR_strToNum(char *tok, Word len)
{
  char *nend;
  Word w = strtoul(tok, &nend, 10);
  if ((Word)(nend - tok) != len || w > UINT_MAX)
    die(ExcBadNumber);
  return w;
}

static Register
asmR_intReg(asmR_State *R)
{
  char *tok;
  Word len = asmR_tok(R, &tok, isdigit);
  Word r = asmR_strToNum(tok, len);
  if (r > REGISTER_MAX)
    die(ExcBadRegister);
  return r;
}

static Register
asmR_intRegFS(asmR_State *R)
{
  asmR_skipSpace(R);
  switch (*(R->ptr)) {
  case 'S':
    (char *)(R->ptr)++;
    return REGISTER_S;
  case 'F':
    (char *)(R->ptr)++;
    return REGISTER_F;
  }
  return asmR_intReg(R);
}

static Size
asmR_size(asmR_State *R)
{
  char *tok;
  Size s = 0;
  Word n;
  Word len = asmR_tok(R, &tok, isalnum);
  if (len == 1 && *tok == 'a')
    return SIZE_W;
  n = asmR_strToNum(tok, len);
  if (n == 0 || n & (n - 1))    /* Sizes have exactly one bit set */
    die(ExcBadSize);
  do {
    n >>= 1;
    s++;
  } while (n);
  return s;
}

static ArgType
asmR_argTy(asmR_State *R, Word *size)
{
  char *tok;
  ArgType ty;
  Word len = asmR_tok(R, &tok, isalnum);
  if (len > 1) {
    if (*tok != 'b')
      die(ExcBadArgType);
    ty = ARG_TYPE_B;
    *size = asmR_strToNum(tok, len);
  } else
    switch (*tok) {
    case 'r':
      ty = ARG_TYPE_R;
      break;
    case 'f':
      ty = ARG_TYPE_F;
      break;
    default:
      die(ExcBadArgType);
    }
  return ty;
}

static LabelType
asmR_labTy(asmR_State *R)
{
  char *tok;
  Word len = asmR_tok(R, &tok, isalpha);
  if (len == 1)
    switch (*tok) {
    case 'b':
      return LABEL_B;
    case 's':
      return LABEL_S;
    case 'd':
      return LABEL_D;
    case 'f':
      return LABEL_F;
    }
  die(ExcBadLabelType);
}

static List *
asmR_lab(asmR_State *R, LabelType ty)
{
  char *tok;
  Label *l;
  List *hp;
  uint32_t hEntry;
  asmR_tok(R, &tok, asmR_isSym);
  hp = hashGet(R->labHash, tok, &hEntry);
  if (hp) {
    l = hp->body;
    if (l->ty != ty)
      die(ExcWrongLabel);
    return hp;
  } else {
    l = new(Label);
    l->ty = ty;
    l->v.n = 0;
    return hashSet(R->labHash, hp, hEntry, tok, l);
  }
}

static Word
asmR_num(asmR_State *R)
{
  char *tok;
  Word len = asmR_tok(R, &tok, isdigit);
  return asmR_strToNum(tok, len);
}

static Word
asmR_imm(asmR_State *R, Byte *f, SByte *sgn, int *r)
{
  int rsgn;
  long rl;
  char *tok, *nend;
  Word v;
  asmR_tok(R, &tok, asmR_isImm);
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
  v = strtoul(tok, &nend, 0);
  if (errno == ERANGE || (*sgn && v > (unsigned long)(LONG_MAX) + 1))
    /* rather than -LONG_MIN; we're assuming two's complement anyway,
       and negating LONG_MIN overflows long */
    die(ExcBadImmVal);
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
      die(ExcBadImmRot);
    tok = nend;
    *r = rsgn ? -(int)rl : (int)rl;
  } else
    *r = 0;
  if (*tok)
    die(ExcBadImm);
  return v;
}

static LabelValue
asmR_labelAddr(asmR_State *R, Label *l)
{
  LabelValue ret;
  List *hp;
  uint32_t hEntry;
  hp = hashGet(R->labHash, (char *)l->v.p, &hEntry);
  ret.p = (hp != NULL) ? ((Label *)hp->body)->v.p : NULL;
  return ret;
}

static asmR_State *
asmR_readerNew(asmR_Input *inp)
{
  asmR_State *R = new(asmR_State);
  R->ptr = R->img = inp->img;
  R->end = inp->img + inp->size;
  return R;
}]],

  inst = {},

  trans = Translator {
    "",                              -- decl
    [[R->labHash = hashNew(4096);
  R->eol = 0;]],                     -- init
    "o = asmR_inst(R);",             -- update
    "",                              -- finish
  },
}

rOpType = {
  r = OpType {"Register r%n;", "r%n = asmR_intReg(R);"},
  R = OpType {"Register r%n;", "r%n = asmR_intRegFS(R);"},
  s = OpType {"Size s%n;", "s%n = asmR_size(R);"},
  i = OpType {[[Byte i%n_f;
        SByte i%n_sgn;
        int i%n_r;
        Word i%n_v;]],
    "i%n_v = asmR_imm(R, &i%n_f, &i%n_sgn, &i%n_r);"},
  n = OpType {"Word n%n;", "n%n = asmR_num(R);"},
  t = OpType {"LabelType t%n;", "t%n = asmR_labTy(R);"},
  l = OpType {[[List *l%n_l;
        LabelValue l%n;]],
    function (inst, op)
      local ty = labelType (inst, op)
      return "l%n_l = asmR_lab(R, " .. ty .. [[);
        l%n.p = l%n_l->key;]]
  end},
  x = OpType {[[List *x%n_l;
        Label *x%n;]],
    function (inst, op)
      local ty = labelType (inst, op)
      return "x%n_l = asmR_lab(R, " .. ty ..
        [[);
        x%n = x%n_l->body;
        if (x%n->v.n)
          die(ExcDupLabel, x%n_l->key);
        x%n->v.n = ++T->labels[]] .. ty .. "];"
    end},
  a = OpType {[[Size a%n_size;
        ArgType a%n_ty;]],
    "a%n_ty = asmR_argTy(R, &a%n_size);"},
}

-- FIXME: The rest should be in mkTrans.lua or util.lua

-- Check the reader implements the correct opTypes
checkReaderOpTypes (opType, r, rOpType)

-- Compute the instruction definitions
for i = 1, #inst do
  local inst = inst[i]
  local decl, code = "", ""

  -- Add the declarations
  for j = 1, #inst.ops do
    local opType, opRepeat = getOpInfo (inst.ops[j])
    local opDecl = rOpType[opType].decl (inst, j)
    if opDecl ~= "" then
      decl = decl .. opDecl .. "\n"
    end
  end

  -- Add the code
  for j = 1, #inst.ops do
    local opType, opRepeat = getOpInfo (inst.ops[j])
    local opCode = rOpType[opType].code (inst, j)
    if opCode ~= "" then
      if opRepeat then
        code = code .. "for (size_t i = 1; i <= n" .. tostring (j - 1)
          .. "; i++) {\n  "
      end
      code = code .. opCode .. "\n"
      if opRepeat then
        code = code .. "}\n"
      end
    end
  end

  r.inst[i] = Inst {inst.name, decl, code}
end

return r
