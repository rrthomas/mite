/* Open hash tables
   (c) Reuben Thomas 1996
*/


#include <stdlib.h>
#include <string.h>
#include "except.h"
#include "hash.h"

HashTable *
hashNew(size_t size, Hasher hash, Comparer compare)
{
  HashTable *table = new(HashTable);
  table->thread = excCalloc(size, sizeof(HashNode *));
  table->size = size;
  table->hash = hash;
  table->compare = compare;
  return table;
}

void
hashDestroy (HashTable *table)
{
  size_t i;
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

typedef struct {
  size_t entry;
  HashNode *prev;
  HashNode *curr;
  int found;
} HashLink;

static HashLink
hashSearch(HashTable *table, void *key)
{
  size_t entry = table->hash(key) % table->size;
  HashLink ret;
  ret.entry = entry;
  ret.prev = NULL;
  ret.curr = table->thread[entry];
  ret.found = HASH_NOTFOUND;
  while (ret.curr != NULL) {
    if (table->compare(key, ret.curr->key)) {
      ret.found = HASH_FOUND;
      return ret;
    }
    ret.prev = ret.curr;
    ret.curr = ret.curr->next;
  }
  return ret;
}

void *
hashFind(HashTable *table, void *key)
{
  HashLink l = hashSearch(table, key);
  if (l.found == HASH_NOTFOUND)
    return NULL;
  return l.curr->body;
}

void *
hashInsert(HashTable *table, void *key, void *body)
{
  HashLink l = hashSearch(table, key);
  HashNode *n;
  if (l.found == HASH_FOUND)
    return l.curr->body;
  n = excMalloc(sizeof(HashNode));
  if (l.prev == NULL)
    table->thread[l.entry] = n;
  else
    l.prev->next = n;
  n->next = l.curr;
  n->key = key;
  n->body = body;
  return NULL;
}

int
hashRemove(HashTable *table, void *key)
{
  HashLink l = hashSearch(table, key);
  if (l.found == HASH_NOTFOUND)
    return HASH_NOTFOUND;
  if (l.prev == NULL)
    table->thread[l.entry] = l.curr->next;
  else
    l.prev->next = l.curr->next;
  free(l.curr->key);
  free(l.curr->body);
  free(l.curr);
  return HASH_OK;
}

size_t
hashStrHash(void *str)
{
  char *p, *s = (char *)str;
  unsigned long h = 0, g;
  for (p = s; *p != '\0'; p++) {
    h = (h << 4) + *p;
    if ((g = h & 0xf0000000)) {
      h ^= (g >> 24);
      h ^= g;
    }
  }
  return h;
}

int hashStrcmp(void *s, void *t)
{
  return (strcmp((char *)s, (char *)t) == 0);
}
