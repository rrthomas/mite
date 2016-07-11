/* Exception handling
   (c) Reuben Thomas 1997
*/


#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "except.h"
#include "list.h"


const char *_excMsg[] = {
#include "excMsg.h"
};

unsigned long excPos = 0;
char *excFile = NULL;

static void
vWarn (int exc, va_list arg)
{
  if (progName)
    fprintf (stderr, "%s:", progName);
  if (excFile)
    fprintf (stderr, "%s:", excFile);
  if (excPos)
    fprintf (stderr, "%lu:", excPos);
  if (progName || excFile || excPos)
    putc (' ', stderr);
  vfprintf (stderr, _excMsg[exc - 1], arg);
  va_end (arg);
  putc ('\n', stderr);
}

void
warn (int exc, ...)
{
  va_list ap;
  va_start (ap, exc);
  vWarn (exc, ap);
}

void
die (int exc, ...)
{
  va_list ap;
  va_start (ap, exc);
  vWarn (exc, ap);
  exit (EXIT_FAILURE);
}

void *
excMalloc (size_t size)
{
  void *p = malloc (size);
  if (!p && size)
    die (ExcMalloc);
  return p;
}

void *
excCalloc (size_t nobj, size_t size)
{
  void *p = calloc (nobj, size);
  if (!p && nobj && size)
    die (ExcMalloc);
  return p;
}

void *
excRealloc (void *p, size_t size)
{
  if (!(p = realloc (p, size)) && size)
    die (ExcRealloc);
  return p;
}
