/* Open string hash tables
   (c) Reuben Thomas 1996
*/


#ifndef MITE_HASH
#define MITE_HASH


#include <stdint.h>


struct _HashNode {
  struct _HashNode *next;
  char *key;
  void *body;
};
typedef struct _HashNode HashNode;

typedef struct {
    HashNode **thread;
    uintptr_t size;
} HashTable;

typedef struct {
  uint32_t entry;
  HashNode *prev;
  HashNode *curr;
  int found;
} HashLink;

HashTable *hashNew (uintptr_t size);
void hashDestroy (HashTable *table);
void hashGet (HashTable *table, char *key, HashLink *l);
HashNode *hashSet (HashTable *table, HashLink *l, char *key, void *body);
uint32_t strHash (char *str);

#endif
