/* File utilities
   (c) Reuben Thomas 2000
*/


#include <stdio.h>

#include "buffer.h"
#include "const.h"
#include "file.h"


long
flen (FILE *fp)
{
  long pos = ftell (fp);
  if (pos != -1 && fseek (fp, 0, SEEK_END) == 0) {
    long len = ftell (fp);
    if (len != -1 && fseek (fp, pos, SEEK_SET) == 0)
      return len;
  }
  return -1;
}

long
readFile (const char *file, Byte **data)
{
  FILE *fp;
  Byte *p;
  long len = 0;
  size_t max;
  if (*file == '-' && (file[1] == '\0' || file[1] == '.')) {
    fp = stdin;
    *data = bufNew (max, INIT_IMAGE_SIZE);
    p = *data;
    while (!feof (fp) && !ferror (fp)) {
      len += fread (p, sizeof (Byte), max, fp);
      p += len;
      bufExt (*data, max, max * 2);
    }
    if (len == 0)
      die (ExcEmptyFile, "stdin");
    bufShrink (*data, len + 1);
  } else {
    fp = fopen (file, "rb");
    if (!fp)
      die (ExcFopen, excFile);
    if ((len = flen (fp)) < 0)
      die (ExcFlen, excFile);
    if (len == 0)
      die (ExcEmptyFile, excFile);
    *data = excMalloc (len + 1);
    if (fread (*data, sizeof (Byte), len, fp) != (size_t)len)
      die (ExcFread, file);
  }
  (*data)[len] = '\0';
  fclose (fp);
  return len;
}

void
writeFile (const char *file, Byte *data, long len)
{
  FILE *fp = *file == '-' && (file[1] == '\0' || file[1] == '.') ?
    stdout : fopen (file, "wb");
  if (!fp)
    die (ExcFopen, file);
  if (fwrite (data, sizeof (Byte), len, fp) != (size_t)len)
    die (ExcFwrite, file);
  if (fp != stdout) fclose (fp);
}
