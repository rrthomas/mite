/* Array of translators */

#include "translators.h"

TState *(*translator[Interp][Interp])(Byte *, Byte *) =
{{NULL, &objToAsm, &objToInterp},
 {&asmToObj, NULL, NULL},
 {NULL, NULL, NULL}
};
