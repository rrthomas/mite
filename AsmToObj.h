/* Mite assembly to object translator
 * Reuben Thomas    19/5/01 */


#ifndef MITE_ASMTOOBJ
#define MITE_ASMTOOBJ


#include "Translate.h"

#define TRANSLATOR translateAsmToObj
Translator *
TRANSLATOR(Byte *rImg, Byte *rEnd);

#endif
