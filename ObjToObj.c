/* Mite object to object translator
 * Reuben Thomas    21/4-14/5/01 */

/* This translator can be used to check the validity of object files */


#include "Translate.h"

#define TRANSLATOR objToObj
TranslatorFunction TRANSLATOR;

#include "ObjWrite.c"
#include "ObjRead.c"
