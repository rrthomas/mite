/* Open string hash tables
   (c) Reuben Thomas 1996
*/


#ifndef MITE_HASH
#define MITE_HASH

#include "config.h"

#include <stdint.h>


typedef struct _List {
  struct _List *next;
  char *key;
  void *body;
} List;

typedef struct {
  List **thread;
  uintptr_t size;
} Hash;

Hash *hashNew (uintptr_t size);
void hashDestroy (Hash *table);
List *hashGet (Hash *table, char *key, uint32_t *entry);
List *hashSet (Hash *table, List *p, uint32_t entry,
                   char *key, void *body);
uint32_t strHash (char *str);

#endif
