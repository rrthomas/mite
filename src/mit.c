/* Mite translator
   (c) Reuben Thomas 2000
*/


#include <stdio.h>
#include <limits.h>

#include "translate.h"
#include "translators.h"


#if CHAR_BIT != 8
#  error "Mite needs 8-bit chars"
#endif

char *progName;

typedef enum {
  None, Obj, Asm, Interp
} FileType;

static FileType
typeFromSuffix (const char *s)
{
  if (strcmp (s, "o") == 0)
    return Obj;
  else if (s == NULL || *s == '\0' || strcmp (s, "s") == 0)
    return Asm;
  else if (strcmp (s, "interp") == 0)
    return Interp;
  return None;
}

static const char *
suffix (const char *s)
{
  const char *suff = strrchr (s, '.');
  if (suff)
    suff++;
  return suff;
}

int
main (int argc, char *argv[])
{
  Byte *img;
  const char *rSuff, *wSuff, *outFile = argc == 3 ? argv[2] : "-";
  unsigned long size;
  FileType r, w;
  progName = argv[0];
  if (argc < 2 || argc > 3) {
    progName = NULL;
    die (ExcMitUsage, argv[0]);
  }
  excFile = argv[1];
  size = readFile (excFile, &img);
  rSuff = suffix (argv[1]);
  if ((r = typeFromSuffix (rSuff)) == None)
    die (ExcMitBadInType, rSuff ? rSuff : "");
  if (argc == 3) {
    wSuff = suffix (argv[2]);
    if ((w = typeFromSuffix (wSuff)) == None)
      die (ExcMitBadOutType, wSuff ? wSuff : "");
  } else
    w = Asm;
  excPos = 1;
  /* if (r == Obj) {
   *   objR_Input *inp = new (objR_Input);
   *   inp->cImg = img;
   *   inp->cSize = size;
   *   if (w == Asm) {
   *     asmW_Output *out = objToAsm (inp);
   *     writeFile (outFile, (Byte *)out->img, out->size);
   *   } else if (w == Interp) {
   *     interpW_Output *out = objToInterp (inp);
   *     objToRun (out);
   *   }
   * } else  */if (r == Asm && w == Obj) {
    asmR_Input *inp = new (asmR_Input);
    objW_Output *out;
    inp->img = (char *)img;
    inp->size = size;
    out = asmToObj (inp);
    writeFile (outFile, out->img, out->size);
  } else
    die (ExcMitNoTranslator, rSuff, wSuff);
  free (img);
  return EXIT_SUCCESS;
}
