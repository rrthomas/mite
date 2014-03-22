/* Mite instruction name to opcode hash table
   (c) Reuben Thomas 2001
*/

#ifndef MITE_INSTS
#define MITE_INSTS


#include "instEnum.h"

#include <string.h>

#ifdef __GNUC__
__inline
#if defined __GNUC_STDC_INLINE__ || defined __GNUC_GNU_INLINE__
__attribute__ ((__gnu_inline__))
#endif
#endif
struct Inst *
findInst (register const char *str, register unsigned int len);

#endif
