/* Exception handling
   (c) Reuben Thomas 1997
*/


#ifndef MITE_EXCEPT
#define MITE_EXCEPT


#include <stdlib.h>
#include <stdarg.h>
#include <setjmp.h>


#undef FALSE
#undef TRUE
#define FALSE 0
#define TRUE 1

void excInit(void);
void vWarn(const char *fmt, va_list arg);
void warn(const char *fmt, ...);
void vDie(const char *fmt, va_list arg);
void die(const char *fmt, ...);
void vThrow(const char *fmt, va_list arg);
void throw(const char *fmt, ...);

#define try if (!setjmp(*_excEnv()))
#define catch

jmp_buf *_excEnv(void);
void _endTry(void);
void *excMalloc(size_t size);
void *excCalloc(size_t nobj, size_t size);
void *excRealloc(void *p, size_t size);

#define new(T) excMalloc(sizeof(T))

extern unsigned long excLine;
extern char *excFile;
extern char *progName;

#endif