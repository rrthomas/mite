/* Open string hash tables
   (c) Reuben Thomas 1996
*/


#include <stdlib.h>
#include <string.h>

#include "except.h"
#include "hash.h"


uintptr_t
strHash(char *str)
{
  char *p = str;
  unsigned long h = 0, g;
  for (p = str; *p != '\0'; p++) {
    h = (h << 4) + *p;
    if ((g = h & 0xf0000000)) {
      h ^= (g >> 24);
      h ^= g;
    }
  }
  return h;
}

HashTable *
hashNew(uintptr_t size)
{
  HashTable *table = new(HashTable);
  table->thread = excCalloc(size, sizeof(HashNode *));
  table->size = size;
  return table;
}

void
hashDestroy (HashTable *table)
{
  uintptr_t i;
  HashNode *p, *q;
  for (i = 0; i < table->size; i++)
    for (p = table->thread[i]; p != NULL; p = q) {
      q = p->next;
      free(p->key);
      free(p->body);
      free(p);
    }
  free(table->thread);
  free(table);
}

void
hashGet(HashTable *table, char *key, HashLink *l)
{
  uintptr_t entry = strHash(key) % table->size;
  l->entry = entry;
  l->prev = NULL;
  l->curr = table->thread[entry];
  l->found = 0;
  while (l->curr != NULL) {
    if (strcmp(key, l->curr->key) == 0) {
      l->found = 1;
      return;
    }
    l->prev = l->curr;
    l->curr = l->curr->next;
  }
}

HashNode *
hashSet(HashTable *table, HashLink *l, char *key, void *body)
{
  HashNode *n = new(HashNode);
  if (l->prev == NULL)
    table->thread[l->entry] = n;
  else
    l->prev->next = n;
  n->next = l->curr;
  n->key = key;
  n->body = body;
  return n;
}
