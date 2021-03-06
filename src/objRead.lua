-- Mite object reader
-- (c) Reuben Thomas 2000


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
  reads = "Mite object code",
  input = "typedef interpW_Output objR_Input;",
  prelude =
[[#include <stdint.h>
#include <limits.h>

/* TODO: Need a post-pass to verify everything else (what is there?) */


/* Object reader state */
typedef struct {
  Byte *img;
  Byte *end;
  Byte *ptr;
} objR_State;

/* set excPos to the current offset into the image, then die */
static void
diePos (objR_State *R, int exc)
{
  excPos = R->ptr - R->img;
  die (exc);
}

/* find the number of 1s in a 7-bit number using octal accumulators
   (no. of ones in a 3-bit no. is n - floor (n/2) - floor (n/4)) */
static int
countBits (int n)
{
  int n2, m = 033; /* mask */
  n -= (n2 = (n >> 1) & m);  /* n - floor (n/2) */
  n -= (n2 = (n2 >> 1) & m); /* n - floor (n/2) - floor (n/4) */
  return ((n + (n >> 3)) & 0x7) + (n >> 6);
    /* add 3-bit sub-totals and 7th bit */
}

static Word
objR_getBits (objR_State *R, Word n)
{
#define p R->ptr
  int i, endBit, bits;
  Word w;
  if (p < R->end) {
    do {
      w = 0;
      bits = -1;
      i = INST_BYTES_LEFT (p);
      endBit = *p & (1 << (BYTE_BIT - 1));
      do {
	w = (w << BYTE_BIT) | *p++;
	bits += BYTE_BIT;
	i--;
      } while (i);
      n = (n << (INST_BIT - 1)) + w;
    } while (endBit == 0 && p < R->end);
    n -= 1 << bits;
  }
  if (endBit == 0 && p == R->end)
    diePos (R, ExcBadImm);
  return n;
#undef p
}

static Word
objR_getNum (objR_State *R, int *sgnRet)
{
#define p R->ptr
  Byte *start = p;
  Word h = *p & (BYTE_SIGN_BIT - 1);
  int sgn = -(h >> (BYTE_BIT - 2));
  Word n = objR_getBits (R, (Word)sgn);
  unsigned int len = (unsigned int)(p - start - 1);
    /* Don't count first byte, which is in h */
  if ((BYTE_BIT - 1) * len +
      countBits ((int)(sgn == 0 ? h : ~h & (BYTE_SIGN_BIT - 1)))
      > INST_BIT + sgn)
    diePos (R, ExcBadImmVal);
      /* (BYTE_BIT - 1) * len is the no. of significant bits in the
         bottom bytes countBits (...) is the number in the most
         significant byte if we're reading a negative number, the
         maximum size is one less */
  *sgnRet = sgn;
  return sgn ? (Word)(-(SWord)n) : n;
#undef p
}

#ifndef WORDS_BIGENDIAN

#  define objR_OPCODE \
     (objR_w) & BYTE_MASK
#  define objR_OP(p) \
     (objR_w >> (BYTE_BIT * (p))) & BYTE_MASK

#else /* WORDS_BIGENDIAN */

#  define objR_OPCODE \
     (objR_w >> (BYTE_BIT * 3)) & BYTE_MASK
#  define objR_OP(p) \
     (objR_w >> (BYTE_BIT * (INST_BYTE - (p)))) & BYTE_MASK

#endif /* !WORDS_BIGENDIAN */

#define objR_labelAddr(R, l) \
  l->v

static objR_State *
objR_readerNew (objR_Input *inp)
{
  objR_State *R = new (objR_State);
  R->ptr = R->img = inp->cImg;
  R->end = inp->cImg + inp->cSize;
  return R;
}]],
  inst = {},
  trans = Translator {
    [[InstWord objR_w;
  Byte objR_op1, objR_op2, objR_op3;]],       -- decls
    "",                                       -- init
    [[objR_w = *(InstWord *)R->ptr;
    objR_op1 = objR_OP (1);
    objR_op2 = objR_OP (2);
    objR_op3 = objR_OP (3);
    o = objR_OPCODE;
    R->ptr = (Byte *)(R->ptr) + INST_BYTE;]], -- update
    "",                                       -- finish
  },
}

rOpType = {
  r = OpType {[[#undef r%n
      #define r%n objR_op%n]],
      [[if (r%n == 0 || r%n > INT_REGISTER_MAX) /* FIXME: have a value for R */
        diePos (R, ExcBadRegister);]]},
  s = OpType {[[#undef s%n
      #define s%n objR_op%n]],
      [[if (s%n == 0 || s%n & (s%n - 1))    /* Sizes have exactly one bit set */
        die(ExcBadSize);]]},
  i = OpType {[[#undef i%n_f
      #define i%n_f objR_op%n
      int i%n_sgn, i%n_r;
      Word i%n_v;]],
             function (inst, op)
               return
      [[if (i%n_f & ~(FLAG_R | FLAG_S | FLAG_W | FLAG_E))
        diePos (R, ExcBadImmMod);
      i%n_r = (objR_op%n & FLAG_R) ?
        (R->ptr -= 2 - %n, objR_op]] .. tostring (op + 1) ..
        [[) : ((R->ptr -= 3 - %n), 0);
      i%n_v = objR_getNum (R, &i%n_sgn);]]
             end},
  n = OpType {"LabelValue l%n;",
             function (inst, op)
               return "l%n.n = ++T->labels[t" .. tostring (op - 1) ..
                 "];"
             end},
  t = OpType {[[#undef t%n
      #define t%n objR_op%n]],
      [[if (objR_op%n == 0 || objR_op%n > LABEL_TYPES)
        diePos (R, ExcBadLabelType);]]},
  l = OpType {[[int l%n_sgn;
      LabelValue l%n;]],
             function (inst, op)
               return [[R->ptr -= 4 - %n;
      l%n.n = objR_getNum (R, &l%n_sgn);
      if (l%n_sgn)
        diePos (R, ExcBadLabel);]]
             end},
  x = OpType {},
  a = OpType {},
}
r.opType["R"] = r.opType["r"]

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
