/* Mite translator
   (c) Reuben Thomas 2000
*/


#include <stdio.h>
#include <limits.h>

#include "except.h"
#include "buffer.h"
#include "flen.h"
#include "string.h"
#include "translate.h"
#include "translators.h"


#if CHAR_BIT != 8
#  error "Mite needs 8-bit chars"
#endif

char *progName;

enum {
  None, Obj, Asm
};

static unsigned int
typeFromSuffix(const char *s)
{
  if (strcmp(s, "o") == 0) return Obj;
  else if (s == None || *s == '\0' || strcmp(s, "s") == 0) return Asm;
  return None;
}

static const char *
suffix(const char *s)
{
  const char *suff = strrchr(s, '.');
  if (suff) suff++;
  return suff;
}

static long
readFile(const char *file, Byte **data)
{
  FILE *fp;
  Byte *p;
  long len = 0;
  uintptr_t max;
  if (*file == '-' && (file[1] == '\0' || file[1] == '.')) {
    fp = stdin;
    *data = bufNew(max, MIN_IMAGE_SIZE);
    p = *data;
    while (!feof(fp)) {
      len += fread(p, sizeof(Byte), max, fp);
      p += len;
      bufExt(*data, max, max * 2);
    }
    if (len == 0) throw("empty input");
    bufShrink(*data, len + 1);
  } else {
    fp = fopen(file, "rb");
    if (!fp) throw("could not open `%s'", excFile);
    if ((len = flen(fp)) < 0) throw("error getting length of file");
    if (len == 0) throw("empty file `%s'", excFile);
    *data = excMalloc(len + 1);
    if (fread(*data, sizeof(Byte), len, fp) != (uintptr_t)len)
      throw("error reading `%s'", file);
  }
  (*data)[len] = '\0';
  fclose(fp);
  return len;
}

static void
writeFile(const char *file, Byte *data, long len)
{
  FILE *fp = *file == '-' && (file[1] == '\0' || file[1] == '.') ?
    stdout : fopen(file, "wb");
  if (!fp) throw("could not open `%s'", file);
  if (fwrite(data, sizeof(Byte), len, fp) != (uintptr_t)len)
    throw("error writing '%s'", file);
  if (fp != stdout) fclose(fp);
}

int
main(int argc, char *argv[])
{
  Byte *img;
  const char *rSuff, *wSuff;
  long len;
  TState *t = NULL;
  unsigned int r, w;
  progName = argv[0];
  excInit();
  if (argc < 2 || argc > 3) {
    progName = NULL;
    die("Usage: %s [-o file] file", argv[0]);
  }
  excFile = argv[1];
  len = readFile(excFile, &img);
  rSuff = suffix(argv[1]);
  if ((r = typeFromSuffix(rSuff)) == None)
    die("unknown input file type `%s'", rSuff ? rSuff : "");
  if (argc == 3) {
    wSuff = suffix(argv[2]);
    if ((w = typeFromSuffix(wSuff)) == None)
      die("unknown output file type `%s'", wSuff ? wSuff : "");
  } else w = Asm;
  excLine = 1;
  switch (r) {
  case Asm: if (w == Obj) t = asmToObj(img, img + len); break;
  case Obj:
    switch (w) {
    case Asm: t = objToAsm(img, img + len); break;
    }
  }
  if (!t) die("no translator from `%s' to `%s'", rSuff, wSuff);
  /* Translate by more than one step */
  free(img);
  writeFile(argc == 3 ? argv[2] : "-", t->wImg, (long)(t->wPtr - t->wImg));
  return EXIT_SUCCESS;
}
