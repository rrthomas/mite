/* ANSI-C code produced by gperf version 2.7.2 */
/* Command-line: gperf -L ANSI-C -N findInst -t -k '1,2,$' insts.gperf  */
#include "insts.h"
struct Inst { const char *name; unsigned int opcode; };

#define TOTAL_KEYWORDS 35
#define MIN_WORD_LENGTH 1
#define MAX_WORD_LENGTH 5
#define MIN_HASH_VALUE 2
#define MAX_HASH_VALUE 100
/* maximum key range = 99, duplicates = 0 */

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
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101,  11,  35,   5,
       15,   0,  10,   5,  15,  15, 101, 101,   0,  25,
       30,  56,  10,  25,   0,   0,   5,  45,   5, 101,
       25, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101, 101, 101, 101, 101,
      101, 101, 101, 101, 101, 101
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
struct Inst *
findInst (register const char *str, register unsigned int len)
{
  static struct Inst wordlist[] =
    {
      {""}, {""},
      {"sl", OP_SL},
      {"srl", OP_SRL},
      {"sets", OP_SETS},
      {""}, {""}, {""},
      {"ret", OP_RET},
      {"gets", OP_GETS},
      {""}, {""},
      {"st", OP_ST},
      {"tlt", OP_TLT},
      {"sra", OP_SRA},
      {"space", OP_SPACE},
      {""}, {""},
      {"ldl", OP_LDL},
      {"litl", OP_LITL},
      {"call", OP_CALL},
      {"callr", OP_CALLR},
      {""},
      {"lit", OP_LIT},
      {""}, {""}, {""}, {""},
      {"rem", OP_REM},
      {""}, {""}, {""},
      {"ld", OP_LD},
      {"teq", OP_TEQ},
      {""}, {""}, {""},
      {"br", OP_BR},
      {"div", OP_DIV},
      {""}, {""}, {""}, {""}, {""},
      {"add", OP_ADD},
      {""}, {""},
      {"bt", OP_BT},
      {""},
      {"lab", OP_LAB},
      {""},
      {"calln", OP_CALLN},
      {""}, {""},
      {"tltu", OP_TLTU},
      {""}, {""},
      {"bf", OP_BF},
      {"or", OP_OR},
      {"and", OP_AND},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""},
      {"b", OP_B},
      {""},
      {"mul", OP_MUL},
      {"push", OP_PUSH},
      {""}, {""}, {""}, {""},
      {"pop", OP_POP},
      {""}, {""}, {""},
      {"sub", OP_SUB},
      {"xor", OP_XOR},
      {""}, {""}, {""}, {""},
      {"mov", OP_MOV},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
      {"movi", OP_MOVI}
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
