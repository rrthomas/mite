/* Mite translators
   (c) Reuben Thomas 2001
*/


#ifndef MITE_TRANSLATORS
#define MITE_TRANSLATORS


#include "translate.h"

TState *
asmToObj(Byte *rImg, Byte *rEnd);

TState *
objToAsm(Byte *rImg, Byte *rEnd);

TState *
objToInterp(Byte *rImg, Byte *rEnd);

#endif
