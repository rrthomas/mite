/* Mite object to interpretive code translator
 * Reuben Thomas    29/4/01 */


#include "Translate.h"

#define TRANSLATOR objToInterp
TranslatorFunction TRANSLATOR;

#include "InterpWrite.c"
#include "ObjRead.c"
