/* Mite public header
   (c) Reuben Thomas 2000
*/


#include <limits.h>
#if CHAR_BIT != 8
#error "Mite needs 8-bit bytes"
#endif

#include <stdint.h>
#include <setjmp.h>
#include "mite_i.h"

#define mite_w (sizeof(mite_Word) * CHAR_BIT)

typedef struct {
    mite_Word (*R)[256], *M;
    mite_State_i _i;
} mite_State;

void mite_push(mite_Word w);
mite_Word mite_pop(void);

typedef uint32_t *mite_Object;

mite_Program *mite_translate(mite_Object o, jmp_buf env, uint32_t **errp);
mite_Word mite_run(mite_Program *p, mite_State *s, jmp_buf env);

#define mite_internalError   1
#define mite_memoryFull      2
#define mite_badP            3
#define mite_badS            4
#define mite_badAddress      5
#define mite_divisionByZero  6
#define mite_badShift        7
#define mite_badInstruction  8
#define mite_badHeader       9
