/* Open string hash tables
   (c) Reuben Thomas 1996
*/


#include <stdlib.h>
#include <string.h>

#include "except.h"
#include "hash.h"


Hash *
hashNew (uintptr_t size)
{
  Hash *table = new (Hash);
  table->thread = excCalloc (size, sizeof (List *));
  table->size = size;
  return table;
}

void
hashDestroy (Hash *table)
{
  uintptr_t i;
  List *p, *q;
  for (i = 0; i < table->size; i++)
    for (p = table->thread[i]; p != NULL; p = q) {
      q = p->next;
      free (p->key);
      free (p->body);
      free (p);
    }
  free (table->thread);
  free (table);
}

List *
hashGet (Hash *table, char *key, uint32_t *entry)
{
  List *p;
  *entry = strHash (key) % table->size;
  for (p = table->thread[*entry]; p != NULL; p = p->next) {
    if (strcmp (key, p->key) == 0)
      return p;
  }
  return NULL;
}

List *
hashSet (Hash *table, List *p, uint32_t entry,
         char *key, void *body)
{
  if (p == NULL) {
    p = new (List);
    p->next = table->thread[entry];
    table->thread[entry] = p;
    p->key = key;
  }
  p->body = body;
  return p;
}

uint32_t
strHash (char *str)
{
  char *p = str;
  uint32_t h = 0, g;
  for (p = str; *p != '\0'; p++) {
    h = (h << 4) + *p;
    if ((g = h & 0xf0000000)) {
      h ^= (g >> 24);
      h ^= g;
    }
  }
  return h;
}
