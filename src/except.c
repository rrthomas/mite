/* Exception handling
   (c) Reuben Thomas 1997
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <setjmp.h>

#include "except.h"
#include "list.h"

#define unVify(vf, f) \
  void\
  f (const char *fmt, ...) \
  { \
    va_list ap; \
    va_start(ap, fmt); \
    vf(fmt, ap); \
    va_end(ap); \
  }

static List *_excBufs;
unsigned long excLine = 0;
char *excFile = NULL;

void
excInit(void)
{
  _excBufs = listNew();
}

void
vWarn(const char *fmt, va_list arg)
{
  if (progName)
    fprintf(stderr, "%s:", progName);
  if (excFile)
    fprintf(stderr, "%s:", excFile);
  if (excLine)
    fprintf(stderr, "%lu:", excLine);
  if (progName || excFile || excLine)
    putc(' ', stderr);
  vfprintf(stderr, fmt, arg);
  va_end(arg);
  putc('\n', stderr);
}
unVify(vWarn, warn)

void
vDie(const char *fmt, va_list arg)
{
  vWarn(fmt, arg);
  exit(EXIT_FAILURE);
}
unVify(vDie, die)

void
vThrow(const char *fmt, va_list arg)
{
  if (!listEmpty(_excBufs))
    longjmp(*((jmp_buf *)_excBufs->next->item), TRUE);
  vDie(fmt, arg);
}
unVify(vThrow, throw)

jmp_buf *
_excEnv(void)
{
  jmp_buf *env = excMalloc(sizeof(jmp_buf));
  listPrefix(_excBufs, env);
  return env;
}

void
_endTry(void)
{
  if (!listEmpty(_excBufs))
    listBehead(_excBufs);
}
#define endTry _endTry()

void *
excMalloc(size_t size)
{
  void *p = malloc(size);
  if (!p && size)
    throw("could not allocate memory");
  return p;
}

void *
excCalloc(size_t nobj, size_t size)
{
  void *p = calloc(nobj, size);
  if (!p && nobj && size)
    throw("could not allocate memory");
  return p;
}

void *
excRealloc(void *p, size_t size)
{
  if (!(p = realloc(p, size)) && size)
    throw("could not reallocate memory");
  return p;
}
