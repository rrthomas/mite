/* Exception handling
   (c) Reuben Thomas 1997
*/


#ifndef MITE_EXCEPT
#define MITE_EXCEPT


#include <stdlib.h>
#include <stdarg.h>
#include <setjmp.h>

void excInit (void);
void vWarn (const char *fmt, va_list arg);
void warn (const char *fmt, ...);
void vDie (const char *fmt, va_list arg);
void die (const char *fmt, ...);
void vThrow (int exc, va_list arg);
void throw (int exc, ...);

#define try \
  { \
    int _exc; \
    if ((_exc = setjmp (*_excEnv ())) == 0)
#define catch else
#define endTry \
  _endTry (); \
  }

jmp_buf *_excEnv (void);
void _endTry (void);
void *excMalloc (size_t size);
void *excCalloc (size_t nobj, size_t size);
void *excRealloc (void *p, size_t size);

#define new(T) excMalloc (sizeof (T))

extern unsigned long excPos;
extern char *excFile;
extern char *progName;

typedef enum {
#include "excEnum.h"
} Exception;

#endif
