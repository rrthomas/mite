/* Mite translators
   (c) Reuben Thomas 2001
*/


#ifndef MITE_TRANSLATORS
#define MITE_TRANSLATORS


#include "translate.h"

Translator *
asmToObj(Byte *rImg, Byte *rEnd);

Translator *
objToObj(Byte *rImg, Byte *rEnd);

Translator *
objToInterp(Byte *rImg, Byte *rEnd);

#endif
