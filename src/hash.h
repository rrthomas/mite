/* Open hash tables
   (c) Reuben Thomas 1996
*/


#ifndef MITE_HASH
#define MITE_HASH


struct _HashNode { struct _HashNode *next; void *key; void *body; };
typedef struct _HashNode HashNode;

typedef size_t (*Hasher)(void *);
typedef int (*Comparer)(void *, void *);

typedef struct {
    HashNode **thread;
    size_t size;
    Hasher hash;
    Comparer compare;
} HashTable;

HashTable *hashNew(size_t size, Hasher hash, Comparer compare);
void hashDestroy(HashTable *table);
void *hashFind(HashTable *table, void *key);
void *hashInsert(HashTable *table, void *key, void *body);
int hashRemove(HashTable *table, void *key);


#define HASH_OK 0
#define HASH_FOUND 1
#define HASH_NOTFOUND 2

size_t hashStrHash(void *);
int hashStrcmp(void *, void *);

#endif
