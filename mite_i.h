
#line 123 "mit.w"

#line 165 "mit.w"
typedef intptr_t miteWord;
typedef uintptr_t miteUWord;

#define mite_s  -1
#define mite_g   8

#line 123 "mit.w"


#line 309 "mit.w"
typedef struct {
  uint32_t *code, *cend;
  miteWord *data, dlen, *bl, *sl, *dl, b, s, d;
} miteProgram;

#line 320 "mit.w"
typedef struct {
  miteWord *S_base, S_size;
} mite_State_i;

#line 124 "mit.w"

