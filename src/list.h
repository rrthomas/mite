/* Linked lists
   (c) Reuben Thomas 1997
*/


#ifndef MITE_LIST
#define MITE_LIST


struct _List {
    struct _List *prev;
    struct _List *next;
    void *item;
};
typedef struct _List List;

List *listNew(void);
int listEmpty(List *l);
List *listPrefix(List *l, void *i);
void *listBehead(List *l);

#endif
