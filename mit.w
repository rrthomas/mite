%
% mit, the Mite translator
%
% Reuben Thomas   20/5/00-3/4/01
%

% the line below makes lmk -pvc work
%\input{mit.w}

% Do a special h3sm GNU C version (inspired then by Hohensee building on
% Ertl (et al?))

\documentclass[english]{scrartcl}
\usepackage[LY1]{fontenc}
\usepackage{babel,lypslatex,array,booktabs,url}
\usepackage[norefs]{nuweb}
\usepackage{literate}


% Alter some default parameters for general typesetting

\renewcommand{\nuwebdefinedby}{=}


% Macros for this document

\newcommand{\absfont}{\sffamily}
\newcommand{\abs}[1]{{\absfont #1}}



\begin{document}

\title{mit, the Mite translator}
\author{Reuben Thomas\\\url{rrt@@sc3d.org}\\\url{http://sc3d.org/rrt/}}
\date{3rd April 2001}
\maketitle



\section{Introduction}

mit, the \textbf{Mi}te \textbf{t}ranslator, is written in ISO~C, and can be
used stand-alone or embedded in other programs.


\subsection{License}

mit is supplied as is, under BSD license:

\begin{quote}
Copyright \copyright 2001 Reuben Thomas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the ``Software''), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
\end{quote}


\subsection{System requirements}

mit should work on any big or little-endian system with an ISO~C compiler
and the standard libraries, provided:

\begin{itemize}
\item two's complement number representation is used
\item the compiler performs arithmetic right shifts on signed types
\item all pointers are the same size
\end{itemize}

\cont I'd really like to know of any problems, whether because your system
doesn't meet these criteria, or because of a bug in mit.



\section{Interpreter}

The interpreter is contained in ¦interp.c¦. Some functions are compiled
twice, once with ¦MITE_VERIFY¦ defined and once without. The verified
versions have some extra checks for validity of the object code added, which
are not needed during interpretation, once the code has been checked; they
have the prefix ¦ver_¦ added to their names by the ¦MITE_PREFIX¦ macro.

@o interp.c -d
@{
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include "mite.h"

@<Private macros@>
#define MITE_PREFIX(x) x
@<Reading integers@>
#define MITE_VERIFY
#undef MITE_PREFIX
#define MITE_PREFIX(x) ver_ ## x
@<Reading integers@>
@<Functions@>
@<Translate an object file@>
@<Run a program@>
@}

The implementation-specific header is ¦mite_i.h¦. It contains the
implementation-dependent parameters and types.

@o mite_i.h -d
@{
@<Parameters@>
@<Implementation-dependent types@>
@}



\section{Utilities}

Mite uses a few utility macros:

@D Private macros
@{
#define max(a, b)  ((a) > (b) ? (a) : (b))
#define min(a, b)  ((a) < (b) ? (a) : (b))

#define raise(e)   longjmp(env, (int)(e))

#define seta(a, n, i, e, o) \
    if ((i) >= (n)) raise(mite_badHeader); (a)[(i)++]= (miteWord)(e) + (o)

#define alloc(p, s) \
    p= malloc(s);  if (!p) raise(mite_memoryFull)
@| max min raise seta alloc @}

\cont ¦min()¦ and ¦max()¦ are the usual minimum and maximum operators;
¦raise()¦ is a shorthand for raising an exception. ¦seta()¦ sets array
element ¦a[i]¦ to ¦e¦$+$¦o¦, incrementing ¦i¦ and checking that it does not
exceed the size ¦n¦ of the array. ¦alloc()¦ is a wrapper for ¦malloc()¦ that
raises an exception if it runs out of memory.



\section{Parameters}

¦mite_i.h¦ is included by ¦mite.h¦ to define the implementation-specific
parameters and types. mit represents the Mite word by ¦intptr_t¦ and the
unsigned word by ¦uintptr_t¦; there are $8$ general registers by default
(though this can be changed by altering ¦mite_g¦'s definition), and the
stack is descending.

@d Parameters
@{
typedef intptr_t miteWord;
typedef uintptr_t miteUWord;

#define mite_s  -1
#define mite_g   8
@| miteWord miteUWord mite_s mite_g @}

The endianness of the current machine is held in ¦endianness¦, which is
simply a ¦uint32_t¦ set to $1$. It is read via the macro ¦LITTLE_ENDIAN¦,
which looks at the first byte, which will be $1$ on a little-endian machine,
and $0$ on a big-endian machine.

@d Private macros
@{
static uint32_t endianness = 1;
#define LITTLE_ENDIAN  (*(int8_t *)&endianness)
@| endianness LITTLE_ENDIAN @}



\section{Registers and stack}

Some macros are used to access registers and the stack, which depend on ¦R¦
being a register array. ¦P_REG¦ is the register number of the \abs{P}
register; ¦P¦ gives the value of \abs{P} as a pointer to an instruction;
¦Pp¦ gives the address of ¦P¦ as a pointer to ¦miteObject¦, which can be
passed to ¦intg()¦ and ¦num()¦ (section~\ref{numbers}) while reading virtual
code. ¦setP()¦ is used to assign to ¦P¦ (because ANSI~C forbids casting
l-values, and ¦P¦ is actually a member of an array of ¦miteWord¦s, not a
¦uint32_t *¦).

Similarly, ¦S_REG¦ is the register number of \abs{S}, ¦S¦ gives \abs{S}'s
value as a ¦miteWord *¦, and ¦setS()¦ is used to assign to ¦S¦. ¦checkS()¦
is called by ¦setS()¦ and elsewhere to check that \abs{S}'s value is valid
every time it is updated; if not, ¦mite_badS¦ is raised.

@D Private macros
@{
#define P_REG    0x7f
#define P        ((uint32_t *)(R[P_REG]))
#define Pp       (miteObject *)&R[P_REG]
#define setP(x)  R[P_REG]= (miteWord)(x)

#define S_REG    0x7e
#define S        ((miteWord *)(R[S_REG]))
#define setS(x)  checkS(x); R[S_REG]= (miteWord)x;
#define checkS(x) \
    if (((miteWord *)(x) > s->_i.S_base) || \
        ((miteWord *)(x) < s->_i.S_base - s->_i.S_size)) \
            raise(mite_badS);
@| P_REG P Pp setP S_REG S setS checkS @}

The stack is stored in a ¦malloc¦ed block, which is auto-extended using the
¦stack_extend()¦ macro, which is passed the ¦mite_State¦ whose stack it
should extend (including a trailing ¦.¦ or ¦->¦ to indicate the method of
access to the members). This macro is also used to initialise the stack, by
setting the state's ¦S_base¦ to ¦NULL¦, which causes the call to ¦realloc()¦
to allocate a new block of memory. ¦extendS¦ is used during interpretation
before each operation that pushes to the stack, to extend it when full.

@d Private macros
@{
#define stack_extend(s) \
    if (!(s ## _i.S_base= realloc(s ## _i.S_base, \
        (s ## _i.S_size *= 2) * sizeof(miteWord)))) \
            raise(mite_memoryFull)
#define extendS  if (S == s->_i.S_base) stack_extend(s->)
@| stack_extend extendS @}



\section{Numbers} \label{numbers}

These two functions read numbers from a ¦miteObject *¦, updating the
pointer once the number has been read.

¦intg()¦ reads an encoded integer, gathering words until the top bit is
zero, and taking the sign from the first word. When verifying, it takes as
its second parameter a pointer to the end of the object code and checks that
it does not exceed this limit.

@D Reading integers
@{
static miteWord
MITE_PREFIX(intg)(miteObject *p
#ifdef MITE_VERIFY
                  , miteObject l
#endif
)
{
    miteWord n= (**p & 0x40000000 ? -1 : 0);

    do n= (n << 31) | (**p++ & 0x7fffffff);
    while ((*p[-1] & 0x80000000) == 0
#ifdef MITE_VERIFY
    && *p < l
#endif
    );

    return n;
}
@| intg @}

¦num()¦ reads a number with possible use of $e$, $s$, $w$ and rotation.
Because it calls ¦intg()¦, it too must have a verified version.

@D Functions
@{
static void
ver_num(miteObject *p, int flags, miteObject l)
{
    ver_intg(p, l);
    if (flags & 1) ver_intg(p, l);
}

static miteWord
num(miteObject *p, int flags)
{
  miteWord n= intg(p), r;

  if (flags & 8 && !LITTLE_ENDIAN) n= mite_w - n;
  if (flags & 4)                   n *= mite_s;
  if (flags & 2)                   n *= mite_w;
  if (flags & 1) {
    if ((r= intg(p) < 0) r= mite_w + r;
    r= max(0, min(mite_w, r));
    n= ((miteUWord)n >> r) | ((miteUWord)n << (mite_w - r));
  }
  return n;
}
@| num @}


\section{Types}

¦miteProgram¦ holds all the data needed to interpret a program. ¦code¦
points to the start of the object code in the original module, and ¦cend¦
points to the end of the object code; ¦data¦ points to the copied out data,
and ¦dlen¦ is its length; ¦bl¦, ¦sl¦ and ¦dl¦ point to arrays containing the
addresses of the labels, and ¦b¦, ¦s¦ and ¦d¦ give the number of labels of
each types.

@d Implementation-dependent types
@{
typedef struct {
  uint32_t *code, *cend;
  miteWord *data, dlen, *bl, *sl, *dl, b, s, d;
} miteProgram;
@| miteProgram @}

¦mite_State_i¦ holds the base of the stack (¦S_base¦), and the amount of
memory currently allocated for it (¦S_size¦).

@d Implementation-dependent types
@{
typedef struct {
  miteWord *S_base, S_size;
} mite_State_i;
@| mite_State_i @}



\section{Translation}

Before a program is interpreted, it is scanned to find all the labels, which
are stored in arrays for faster access during interpretation, and the
literal data is written into a separate memory block so that it can easily
be read and written. At the same time, the program is verified to check that
all the instructions and their operands are valid.

¦mite_translate()¦ translates a program for interpretation, verifying that
it is valid in the process.

@d Translate an object file
@{
miteProgram *
mite_translate(miteObject o, jmp_buf env, uint32_t **errp)
{
  miteProgram *prog;
  miteObject p;
  miteWord I, *dp= NULL, o1, o2, o3;
@| mite_translate @}


@D Private macros
@{
#define bad_instruction \
  { *errp= p; raise(mite_badInstruction); }
#define OPC(op, t1, t2, t3)  \
  break; case op: t1 ## _opc (o1); t2 ## _opc (o2); t3 ## _opc (o3)
#define __opc(_) \
  if (I & 0xff) bad_instruction; \
  I >>= CHAR_BIT
#define r_opc(r) \
  r= I & 0xff; \
  if (r > mite_g) bad_instruction;\
  I >>= CHAR_BIT
#define i_opc(i) \
  i= I & 0xff; \
  if (i > 7) bad_instruction; \
  ver_num(&p, i, prog->cend); \
  I >>= CHAR_BIT;
#define L_opc(l) \
  if ((I & 0xff) < l_branch || (I & 0xff) > l_data) bad_instruction;
#define l_opc(l) \
  l= ver_intg(&p, prog->cend); \
  I >>= CHAR_BIT;
@| OPC __opc r_opc i_opc L_opc l_opc @}

@D Translate an object file
@{
  {
    miteWord b, s, d;

    for (p= prog->code, b= s= d= 0; p < prog->cend; p++) {
      int flags= (++*p >> CHAR_BIT) & 0xff;

      switch (*p & 0xff) {
        default: bad_instruction;
        OPC(OP_LAB,   L,_,_);  @<Declare a label@>
        OPC(OP_MOV,   r,r,_);
        OPC(OP_MOVI,  r,i,_);
        OPC(OP_LDL,   r,l,_);
        OPC(OP_LD,    r,r,_);
        OPC(OP_ST,    r,r,_);
        OPC(OP_GETS,  r,_,_);
        OPC(OP_SETS,  r,_,_);
        OPC(OP_POP,   r,_,_);
        OPC(OP_PUSH,  r,_,_);
        OPC(OP_ADD,   r,r,r);
        OPC(OP_SUB,   r,r,r);
        OPC(OP_MUL,   r,r,r);
        OPC(OP_DIV,   r,r,r);
        OPC(OP_REM,   r,r,r);
        OPC(OP_AND,   r,r,r);
        OPC(OP_OR,    r,r,r);
        OPC(OP_XOR,   r,r,r);
        OPC(OP_SL,    r,r,r);
        OPC(OP_SRL,   r,r,r);
        OPC(OP_SRA,   r,r,r);
        OPC(OP_TEQ,   r,r,r);
        OPC(OP_TLT,   r,r,r);
        OPC(OP_TLTU,  r,r,r);
        OPC(OP_B,     l,_,_);
        OPC(OP_BR,    r,_,_);
        OPC(OP_BF,    r,l,_);
        OPC(OP_BT,    r,l,_);
        OPC(OP_CALL,  l,_,_);
        OPC(OP_CALLR, r,_,_);
        OPC(OP_RET,   _,_,_);
        OPC(OP_CALLN, r,_,_);
        OPC(OP_LIT,   _,_,_);
        OPC(OP_LITL,  _,_,_);
        OPC(OP_SPACE, _,_,_);
    }
  }
@| mite_translate @}

The number of labels of each type is now checked against the numbers given
in the header; the checks made while setting the values of labels (see
section~\ref{verification}) ensured that there can't be more labels than
required, but there might be fewer.

@d Translate an object file
@{if (b != prog->b || s != prog->s || d != prog->d) raise(mite_badHeader);
@| mite_translate @}

The current value of ¦p¦ is stored as the value of the new label, according
to its type, then the number of labels of the current type is checked to
make sure it doesn't overflow.

@d Declare a label
@{
switch (flags) {
  case l_branch:  seta(prog->bl, prog->b, b, p, 1);   break;
  case l_sub:     seta(prog->sl, prog->s, s, p, 1);   break;
  case l_data:    seta(prog->dl, prog->d, d, dp, 0);  break;
  default:        bad_instruction;
}
@}


\subsection{Verifying and copying data}

Next, the object code is scanned again. The data are copied out, and the
types of label operands are checked.

@D Private macros
@{
#define OPL(op, t, n) \
  break; case op: t ## _opl (o1, n);
#define i_opl(i, n) \
  i= (I >> (CHAR_BIT * n)) & 0xff; \
   num(&p, i);
#define L_opl(l, n) \
  if ((I & 0xff) == 0 || (I & 0xff) > 3) bad_instruction; \
  I >>= CHAR_BIT;
#define b_opl(l, n) \
  l= intg(&p); \
  type= (I >> (CHAR_BIT * n)) & 0xff; \
  if (type != l_branch || l > d) bad_instruction;
#define s_opl(l, n) \
  l= intg(&p); \
  type= (I >> (CHAR_BIT * n)) & 0xff; \
  if (type != l_sub || l > d) bad_instruction;
#define d_opl(l, n) \
  l= intg(&p); \
  type= (I >> (CHAR_BIT * n)) & 0xff; \
  if (type != l_data || l > d) bad_instruction;
@| OPL i_opl L_opl b_opl s_opl d_opl @}

@D Translate an object file
@{
    for (p= prog->code; p < prog->cend; p++) {
      int type;
      miteUWord ops, i;

      switch (*p & 0xff) {
        default: break;
        OPL(OP_MOVI, i, 0);
        OPL(OP_LDL,  d, 1);
        OPL(OP_B,    b, 0);
        OPL(OP_BF,   b, 1);
        OPL(OP_BT,   b, 1);
        OPL(OP_CALL, s, 0);
        case OP_LIT:   @<Copy out a \abs{lit}@>
        case OP_LITL:  @<Copy out a \abs{litl}@>
        case OP_SPACE: @<Copy out a \abs{space}@>
      }
    }
@| mite_translate @}

Finally, the program is returned.

@d Translate an object file
@{
  }

    return prog;
}
@| mite_translate @}


\subsection{Reading data}

For a \abs{lit}, the number of operands, ¦ops¦, is read, and that number of
literal numbers is copied into the data block.

@d Copy out a \abs{lit}
@{
ops= num(&p, *p & 0xff);
for (i= 0; i < ops; i++) *dp++= num(&p, *p & 0xff);
@}

\abs{litl} can refer to the three types of label, whose addresses were
calculated in the previous pass over the object code.

@d Copy out a \abs{litl}
@{
ops= intg(&p);
for (i= 0; i < ops; i++) {
  miteUWord l= intg(&p);

  switch (type) {
    case 1: *dp++= (miteWord)prog->bl[l];  break;
    case 2: *dp++= (miteWord)prog->sl[l];  break;
    case 3: *dp++= (miteWord)prog->dl[l];  break;
  }
}
@}

\abs{space} requires the given number of words to be zero-filled.

@d Copy out a \abs{space}
@{
ops= num(&p, *p & 0xff);

memset(dp, 0, ops * sizeof(miteWord));
dp += ops;
@}


\section{Execution}

\subsection{Operands}

Macros are provided to read operands of each type. The special type ¦_¦ is
for unused operand places.

@D Private macros
@{
#define __op(_)
#define r_op(r) \
  r= I & 0xff; \
  I >>= CHAR_BIT
#define i_op(i) \
  i= num(Pp, I & 0xff); \
  I >>= CHAR_BIT;
#define b_op(l) \
  l= (miteWord)p->bl[intg(Pp)]; \
  I >>= CHAR_BIT;
#define s_op(l) \
  l= (miteWord)p->sl[intg(Pp)]; \
  I >>= CHAR_BIT;
#define d_op(l) \
  l= (miteWord)p->dl[intg(Pp)]; \
  I >>= CHAR_BIT;
@}

Given an instruction's opcode and operand types, ¦OP()¦ declares the
case label and reads the instruction's operands. The ¦break¦ is placed
before to terminate the previous case, as the code for the instruction
immediately follows. So that the first use of ¦OP()¦ in the switch does
not cause a compiler warning, the ¦default¦ case is placed just before
the first call of ¦OP()¦.

@D Private macros
@{
#define OP(op, t1, t2, t3)  \
  break; case op: t1 ## _op (o1); t2 ## _op (o2); t3 ## _op (o3)
@}


\subsection{Interpretation loop}

¦mite_run()¦ repeatedly loads, decodes and executes instructions in
an endless loop. The function is exited by a \abs{ret} instruction when the
stack is empty, or via ¦raise()¦ if an error occurs.

@D Run a program
@{
@<Checks for error conditions@>

miteWord
mite_run(miteProgram *p, mite_State *s, jmp_buf env)
{
  int op;
  uint32_t I;
#define R (*(s->R))
  miteWord o1, o2, o3;

  for (;;) {
    I= *P;  setP(P + 1);
    op= I & 0xff;  I >>= CHAR_BIT;
    switch (op) {
      default:  raise(mite_badInstruction);
      @<Instruction actions@>
    }
  }
#undef R
}
@}

Instructions are dispatched by a switch on the opcode.


\section{Instruction actions} \label{actions}

The default instruction actions are below. The ¦OP¦ macro need not do any
checking of the arguments, as the code being interpreted is known to be
correct. Only run-time errors need be checked. Note that there is no case
for \abs{lab}, which therefore raises \abs{badInstruction} if it is ever
executed. The preprocessing step sets the address of branch and subroutine
labels to the instruction after the \abs{lab} instruction, so no \abs{lab}
instruction should ever actually be executed.

@d Checks for error conditions
@{
#define checkDiv(d)    if (!d) raise(mite_divisionByZero);
#define checkShift(s)  if (s > mite_w) raise(mite_badShift);
@| checkDiv checkShift @}

@D Instruction actions
@{
OP(OP_MOV,   r, r, _);  R[o1]= R[o2];
OP(OP_MOVI,  r, i, _);  R[o1]= num(Pp, o2);
OP(OP_LDL,   r, d, _);  R[o1]= o2;
OP(OP_LD,    r, r, _);  if (R[o2] & (sizeof(miteWord) - 1))
                          raise(mite_badAddress);
                        R[o1]= *(miteWord *)R[o2];
OP(OP_ST,    r, r, _);  if (R[o2] & (sizeof(miteWord) - 1))
                          raise(mite_badAddress);
                        *(miteWord *)R[o1]= R[o2];
OP(OP_GETS,  r, _, _);  R[o1]= (miteWord)S;
OP(OP_SETS,  r, _, _);  setS(R[o1]);
OP(OP_POP,   r, _, _);  R[o1]= *S; setS(S + 1);
OP(OP_PUSH,  r, _, _);  extendS; setS(S - 1); *S= R[o1];
OP(OP_ADD,   r, r, r);  R[o1]= R[o2] + R[o3];
OP(OP_SUB,   r, r, r);  R[o1]= R[o2] - R[o3];
OP(OP_MUL,   r, r, r);  R[o1]= R[o2] * R[o3];
OP(OP_DIV,   r, r, r);  checkDiv((miteUWord)R[o3]);
                        R[o1]= (miteUWord)R[o2] / (miteUWord)R[o3];
OP(OP_REM,   r, r, r);  checkDiv((miteUWord)R[o3]);
                        R[o1]= (miteUWord)R[o2] % (miteUWord)R[o3];
OP(OP_AND,   r, r, r);  R[o1]= R[o2] & R[o3];
OP(OP_OR,    r, r, r);  R[o1]= R[o2] | R[o3];
OP(OP_XOR,   r, r, r);  R[o1]= R[o2] ^ R[o3];
OP(OP_SL,    r, r, r);  checkShift((miteUWord)R[o3]);
                        R[o1]= R[o2] << R[o3];
OP(OP_SRL,   r, r, r);  checkShift((miteUWord)R[o3]);
                        R[o1]= (miteUWord)R[o2] >> R[o3];
OP(OP_SRA,   r, r, r);  checkShift((miteUWord)R[o3]);
                        R[o1]= R[o2] >> R[o3];
OP(OP_TEQ,   r, r, r);  R[o1]= R[o2] == R[o3];
OP(OP_TLT,   r, r, r);  R[o1]= R[o2] < R[o3];
OP(OP_TLTU,  r, r, r);  R[o1]= (miteUWord)R[o2] < (miteUWord)R[o3];
OP(OP_B,     b, _, _);  setP(o1);
OP(OP_BR,    r, _, _);  setP(R[o1]);
OP(OP_BF,    r, b, _);  if (!R[o1]) setP(o2);
OP(OP_BT,    r, b, _);  if (R[o1]) setP(o2);
OP(OP_CALL,  s, _, _);  extendS; setS(S - 1); *S= (miteWord)P; setP(o1 + 1);
OP(OP_CALLR, r, _, _);  extendS; setS(S - 1); *S= (miteWord)P; setP(o1 + 1);
OP(OP_RET,   _, _, _);  setP(*S); setS(S + 1);
OP(OP_CALLN, r, _, _);  (*(void (*)(void))(*(miteWord *)R[o1]))();
@}



\section{Standalone interpreter}

The ¦main()¦ function allocates the stack, prepares the program, and then
starts it by calling ¦mit_run()¦, whose return value is used as mit's
exit code.

@o mit.c -d
@{
int
main(void)
{
  int ret;
  uint32_t *errp;
  miteWord R[256];
  mite_State s;
  jmp_buf env;
  miteProgram *p;

  if (!setjmp(env)) p= mite_translate(program, env, &errp);
  else return (int)errp;

  s.R= &R;
  *s.R[P_REG]= (miteWord)(p->code);
  s._i.S_size= 16;
  s._i.S_base= NULL;
  stack_extend(s.);  *s.R[S_REG]= (miteWord)(s._i.S_base + s._i.S_size);
  if (!(ret = setjmp(env))) mite_run(p, &s, env);

  return ret;
}
@| main @}



\section{Embedding mit}

mit can be embedded in a C program by compiling ¦mit.c¦ into the
program. Since the interpreter has no global state, it can be compiled as a
shared library, and is thread-safe.



\section{Acknowledgements}

mit draws on implementation techniques developed for my earlier Beetle
virtual processor~\cite{beetledis}. Martin Richards introduced me to virtual
machine interpreter implementation techniques via his Cintcode
system~\cite{cintweb}.



\bibliographystyle{plain}
\bibliography{rrt,vm}

\end{document}
