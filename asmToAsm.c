/* Mite assembly to object translator
   (c) Reuben Thomas 2001
*/


#include "translate.h"
#include "translator.h"

#define TRANSLATOR asmToAsm
Translator TRANSLATOR;

#include "asmWrite.c"
#include "asmRead.c"
