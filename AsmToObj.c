/* Mite assembly to object translator
 * Reuben Thomas    14/5/01 */


#include "Translate.h"

#define TRANSLATOR asmToObj
TranslatorFunction TRANSLATOR;

#include "ObjWrite.c"
#include "AsmRead.c"
