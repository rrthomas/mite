/* Exception handling
   (c) Reuben Thomas 1997
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <setjmp.h>

#include "except.h"
#include "list.h"


const char *_excMsg[] = {
#include "excMsg.h"
};

#define unVify(ty, vf, f) \
  void\
  f (ty exc, ...) \
  { \
    va_list ap; \
    va_start (ap, exc); \
    vf (exc, ap); \
    va_end (ap); \
  }

static List *_excBufs;
unsigned long excPos = 0;
char *excFile = NULL;

void
excInit (void)
{
  _excBufs = listNew ();
}

void
vWarn (const char *fmt, va_list arg)
{
  if (progName)
    fprintf (stderr, "%s:", progName);
  if (excFile)
    fprintf (stderr, "%s:", excFile);
  if (excPos)
    fprintf (stderr, "%lu:", excPos);
  if (progName || excFile || excPos)
    putc (' ', stderr);
  vfprintf (stderr, fmt, arg);
  va_end (arg);
  putc ('\n', stderr);
}
unVify (const char *, vWarn, warn)

void
vDie (const char *exc, va_list arg)
{
  vWarn (exc, arg);
  exit (EXIT_FAILURE);
}
unVify (const char *, vDie, die)

void
vThrow (int exc, va_list arg)
{
  if (!listEmpty (_excBufs))
    longjmp (*((jmp_buf *)_excBufs->next->item), exc);
  vDie (_excMsg[exc - 1], arg);
}
unVify (int, vThrow, throw)

jmp_buf *
_excEnv (void)
{
  jmp_buf *env = new (jmp_buf);
  listPrefix (_excBufs, env);
  return env;
}

void
_endTry (void)
{
  if (!listEmpty (_excBufs))
    listBehead (_excBufs);
}

void *
excMalloc (size_t size)
{
  void *p = malloc (size);
  if (!p && size)
    throw (ExcMalloc);
  return p;
}

void *
excCalloc (size_t nobj, size_t size)
{
  void *p = calloc (nobj, size);
  if (!p && nobj && size)
    throw (ExcMalloc);
  return p;
}

void *
excRealloc (void *p, size_t size)
{
  if (!(p = realloc (p, size)) && size)
    throw (ExcRealloc);
  return p;
}
