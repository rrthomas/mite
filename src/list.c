/* Linked lists
   (c) Reuben Thomas 1997
*/


#include <stdlib.h>

#include "except.h"
#include "list.h"


List *
listNew (void)
{
  List *l = new (List);
  l->next = l;
  l->item = NULL;
  return l;
}

int
listEmpty (List *l)
{
  return (l->next == l);
}

List *
listPrefix (List *l, void *i)
{
  List *n = new (List);
  n->next = l->next;
  n->item = i;
  l->next = n;
  return n;
}

void *
listBehead (List *l)
{
  void *i;
  List *d;
  if ((d = l->next) == l) return NULL;
  i = d->item;
  l->next = l->next->next;
  free (d);
  return i;
}
