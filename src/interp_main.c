
#line 691 "mit.w"
int
main(void)
{
  int ret;
  uint32_t *errp;
  miteWord R[256];
  mite_State s;
  jmp_buf env;
  miteProgram *p;

  if (!setjmp(env)) p= mite_translate(program, env, &errp);
  else return (int)errp;

  s.R= &R;
  *s.R[P_REG]= (miteWord)(p->code);
  s._i.S_size= 16;
  s._i.S_base= NULL;
  stack_extend(s.);  *s.R[S_REG]= (miteWord)(s._i.S_base + s._i.S_size);
  if (!(ret = setjmp(env))) mite_run(p, &s, env);

  return ret;
}
