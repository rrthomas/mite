%
% The Mite translator interface
%
% Reuben Thomas   14/7-23/10/00
%

% the line below makes lmk -pvc work
%\input{iface.w}

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

\title{The Mite translator interface}
\author{Reuben Thomas\\\url{rrt@@sc3d.org}\\\url{http://sc3d.org/rrt/}}
\date{23rd October 2000}
\maketitle



\section{Introduction}

The Mite translator interface provides a standard way of interacting with Mite translators, whether implemented as interpreters, just-in-time compilers, or by some other method. The interface is described in generic terms; a ISO~C implementation is also given.



\section{C interface}

The C interface is contained in �mite.h�, which imports a per-implementation header, �mite_i.h�, to define the parameters and implementation-dependent types, which are suffixed �_i�. To avoid name clashes, �mite_� is prefixed to all external identifiers.
The interface is actually ANSI~C89 except for the use of �inttypes.h� to obtain �uint32_t�. �CHAR_BIT� must be $8$.

@o mite.h -d
@{
#include <limits.h>
#if CHAR_BIT != 8
#error "Mite needs 8-bit bytes"
#endif

#include <inttypes.h>
#include <setjmp.h>
#include "mite_i.h"
@}


\subsection{License}

The C interface is supplied as is, under the GNU Lesser General Public License version 2, or at your option, any later version. There is no warranty; use is at the user's risk.



\section{Parameters}

The translator must provide the values it assigns to Mite's parameters: \abs{g} represents $g$, \abs{s} represents $s$, and \abs{w} represents $w$. �mite_Word�, �mite_UWord�, �mite_s� and �mite_g� are defined in �mite_i.h�.

@o mite.h -d
@{#define mite_w (sizeof(mite_Word) * CHAR_BIT)
@| mite_w @}



\section{Types}

A Mite translator should provide the following types:

\begin{description}
\item[\abs{UInt32}]an unsigned $32$-bit integer
\item[\abs{Word}]a signed $w$-bit word
\item[\abs{UWord}]an unsigned $w$-bit word
\item[\abs{State}]the state of a computation
\item[\abs{Object}]an object file
\item[\abs{Program}]a translated program
\end{description}


\subsection{State} \label{state}

A \abs{State} has the following members:

\begin{description}
\item[\abs{R}]the register array
\item[\abs{M}]the memory array
\end{description}

\cont The \abs{S} and \abs{P} registers are therefore accessible via \abs{R}. There may also be implementation dependent information stored in the �mite_State_i� element, �_i�.

@o mite.h -d
@{
typedef struct {
    mite_Word (*R)[256], *M;
    mite_State_i _i;
} mite_State;
@| mite_State @}

\cont In the C implementation, if �M� is �NULL� then $M$ is the address space of Mite's client.

The following methods may be used to manipulate a \abs{State}:

\begin{description}
\item[\abs{push} (\abs{Word} \abs{w}) : ()]Push \abs{w} on to the stack.
\item[\abs{pop} () : (\abs{Word})]Pop a word from the stack.
\end{description}

\cont The stack can be statically allocated, or dynamically extended. \abs{push} can raise \abs{badS} (if the stack overflowed) or \abs{memoryFull} (if there was no memory to extend it); \abs{pop} can raise \abs{badS} (to signal stack underflow).

@o mite.h -d
@{
void mite_push(mite_Word w);
mite_Word mite_pop(void);
@| mite_push mite_pop @}


\subsection{Object}

\abs{Object} is an array of $32$-bit words.

@o mite.h -d
@{typedef uint32_t *mite_Object;
@| mite_Object @}


\subsection{Program}

\abs{Program} is an abstract type; �mite_Program� is defined by �mite_i.h�.



\section{Methods} \label{methods}

A translator should provide the following methods:

\begin{description}
\item[\abs{translate (Object o) : Program}]\ \\\raggedright\abs{raises \{internalError, memoryFull, badInstruction (Word), badHeader\}}\\translates \abs{o} into a runnable program
\item[\abs{run (Program p, State s) : Word}]\ \\\raggedright\abs{raises \{internalError, memoryFull, badP, badS, badAddress, divisionByZero, badShift, badInstruction (Ref UInt32)\}}\\runs program \abs{p} starting in state \abs{s}, and returns the value passed to the \abs{halt} instruction
\end{description}

In the C interface, �translate� uses �errp� to return the number of a \abs{badInstruction} error; in �run� the address is in \abs{P} (�s.R[0xff]�). The �jmp_buf� supplied to each function is used as the destination of �longjmp()� in the event of an exception being raised.

@o mite.h -d
@{
mite_Program *mite_translate(mite_Object o, jmp_buf env, uint32_t **errp);
mite_Word mite_run(mite_Program *p, mite_State *s, jmp_buf env);
@| mite_translate mite_run @}



\section{Errors}

The following errors can be raised by the translator, as detailed above:

\begin{description}
\item[\abs{internalError}]internal error in the translator
\item[\abs{memoryFull}]the translator has run out of memory
\item[\abs{badP}]\abs{P} out of range
\item[\abs{badS}]\abs{S} out of range
\item[\abs{badAddress}]address operand out of range or unaligned
\item[\abs{divisionByZero}]division by zero
\item[\abs{badShift}]shift amount greater than $8w$
\item[\abs{badInstruction (UInt 32)}]there is an invalid instruction in the object module; its address is returned
\item[\abs{badHeader}]the object module's header is invalid
\end{description}

@o mite.h -d
@{
#define mite_internalError   1
#define mite_memoryFull      2
#define mite_badP            3
#define mite_badS            4
#define mite_badAddress      5
#define mite_divisionByZero  6
#define mite_badShift        7
#define mite_badInstruction  8
#define mite_badHeader       9
@| mite_internalError mite_memoryFull mite_badP mite_badS mite_badAddress mite_divisionByZero mite_badShift mite_badInstruction mite_badHeader @}


\end{document}
