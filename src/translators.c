/* Array of translators */

#include "translators.h"

TState *(*translator[Asm][Asm])(Byte *, Byte *) =
{{NULL, &objToAsm}, {&asmToObj, NULL}};
