/* Mite instruction name to opcode hash table
   (c) Reuben Thomas 2001
*/

#ifndef MITE_INSTS
#define MITE_INSTS


#include "opEnum.h"

#include <string.h>

#ifdef __GNUC__
__inline
#endif
struct Inst *
findInst(register const char *str, register unsigned int len);

#endif
