/* Mite object to interpretive code translator
   (c) Reuben Thomas 2001
*/


#include "Translate.h"

#define TRANSLATOR objToInterp
TranslatorFunction TRANSLATOR;

#include "InterpWrite.c"
#include "ObjRead.c"
