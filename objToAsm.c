/* Mite object to assembly translator
   (c) Reuben Thomas 2001
*/


#include "translate.h"
#include "translator.h"

#define TRANSLATOR objToAsm
Translator TRANSLATOR;

#include "asmWrite.c"
#include "objRead.c"
