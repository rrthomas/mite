/* Mite assembly to object translator
   (c) Reuben Thomas 2001
*/


#include "translate.h"

#define TRANSLATOR asmToObj
Translator TRANSLATOR;

#include "objWrite.c"
#include "asmRead.c"
