/* Mite object to object translator
   Reuben Thomas 2001
*/

/* This translator can be used to check the validity of object files */


#include "translate.h"

#define TRANSLATOR objToObj
Translator TRANSLATOR;

#include "objWrite.c"
#include "objRead.c"
