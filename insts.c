/* ANSI-C code produced by gperf version 2.7.2 */
/* Command-line: gperf -L ANSI-C -N findInst -t -k '1,2,$' Insts.gperf  */
struct _Inst { const char *name; unsigned int opcode; };

#define TOTAL_KEYWORDS 35
#define MIN_WORD_LENGTH 1
#define MAX_WORD_LENGTH 5
#define MIN_HASH_VALUE 2
#define MAX_HASH_VALUE 108
/* maximum key range = 107, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
hash (register const char *str, register unsigned int len)
{
  static unsigned char asso_values[] =
    {
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109,  15,  15,   0,
       35,  40,   5,  10,   0,  45, 109, 109,   0,  40,
        5,   0,  35,  25,  10,   0,  30,   0,  25, 109,
       10, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109, 109, 109, 109, 109,
      109, 109, 109, 109, 109, 109
    };
  register int hval = len;

  switch (hval)
    {
      default:
      case 2:
        hval += asso_values[(unsigned char)str[1]];
      case 1:
        hval += asso_values[(unsigned char)str[0]];
        break;
    }
  return hval + asso_values[(unsigned char)str[len - 1]];
}

#ifdef __GNUC__
__inline
#endif
struct _Inst *
findInst (register const char *str, register unsigned int len)
{
  static struct _Inst wordlist[] =
    {
      {""}, {""},
      {"sl", OP_SL},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"srl", OP_SRL},
      {""}, {""}, {""}, {""},
      {"sub", OP_SUB},
      {"call", OP_CALL},
      {""}, {""},
      {"or", OP_OR},
      {"xor", OP_XOR},
      {""},
      {"calln", OP_CALLN},
      {""},
      {"bf", OP_BF},
      {"sra", OP_SRA},
      {""},
      {"callr", OP_CALLR},
      {"b", OP_B},
      {""},
      {"lab", OP_LAB},
      {"tltu", OP_TLTU},
      {""}, {""},
      {"br", OP_BR},
      {"ldl", OP_LDL},
      {"push", OP_PUSH},
      {""}, {""}, {""},
      {"mul", OP_MUL},
      {"sets", OP_SETS},
      {""}, {""}, {""}, {""},
      {"litl", OP_LITL},
      {""}, {""}, {""}, {""},
      {"gets", OP_GETS},
      {""}, {""}, {""},
      {"and", OP_AND},
      {""}, {""}, {""},
      {"st", OP_ST},
      {"tlt", OP_TLT},
      {""}, {""}, {""}, {""},
      {"mov", OP_MOV},
      {""}, {""}, {""},
      {"ld", OP_LD},
      {"pop", OP_POP},
      {""}, {""}, {""},
      {"bt", OP_BT},
      {"lit", OP_LIT},
      {""},
      {"space", OP_SPACE},
      {""}, {""},
      {"ret", OP_RET},
      {""}, {""}, {""}, {""},
      {"add", OP_ADD},
      {"movi", OP_MOVI},
      {""}, {""}, {""},
      {"rem", OP_REM},
      {""}, {""}, {""}, {""},
      {"teq", OP_TEQ},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"div", OP_DIV}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= 0)
        {
          register const char *s = wordlist[key].name;

          if (*str == *s && !strcmp (str + 1, s + 1))
            return &wordlist[key];
        }
    }
  return 0;
}
typedef struct _Inst Inst;
