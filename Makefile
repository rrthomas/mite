# Makefile for Mite
# Reuben Thomas   22/10/99-22/6/01

CC = gcc
WARN = -Wall -W -Wundef -Wpointer-arith -Wbad-function-cast -Wcast-qual \
       -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
CFLAGS = -ansi -pedantic $(WARN) # -O2 -fomit-frame-pointer 
LDFLAGS = -s -L/home/rrt/lib -lm

HEVEA_FLAGS=-I $(HOME)/texmf/hevea -I $(HOME)/texmf/tex/rrt

NUWEB.prg = nuweb -tc
NUWEB.doc = nuweb -npc

# .view is a dummy suffix for viewing DVI files
.SUFFIXES: .w .tex .dvi .ps .pdf .html .view
.w.c:
	$(NUWEB.prg) $<
.w.h:
	$(NUWEB.prg) $<
.w.tex:
	$(NUWEB.doc) -o $@ $<
.tex.dvi:
	lmk -q -co $<
.tex.view:
	lmk -pvc -co $< &
.dvi.ps:
	dvips $<
.ps.pdf:
	ps2pdf $<
.tex.html:
	hevea $(HEVEA_FLAGS) sym.hva package.hva ctable.sty $<

SRCS=Mit.c Translate.c ObjToObj.c AsmToObj.c
OBJS=Mit.o Translate.o ObjToObj.o AsmToObj.o


all: mit

dist: mite.pdf mit.pdf iface.pdf
	rm -f mite.zip
	zip -qr mite.zip Makefile README *.pdf mite.tex *.w \
		*.txt mit.* *.c *.h

mit: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS) -lRRT

mite.h: iface.w
	$(NUWEB.prg) iface.w

Insts.c: Insts.gperf
	gperf -L ANSI-C -N findInst -t -k 1,2,'$$' $< > $@

Endian.h: Endian.c
	$(CC) -o Endian Endian.c
	./Endian > $@

doc: mite.dvi mit.dvi iface.dvi

depend:
	makedepend -I${HOME}/include -- $(CFLAGS) -- $(SRCS)

clean:
	rm -f $(OBJS)
	lmk -clean mite.tex mit.tex iface.tex

# DO NOT DELETE


Mit.o: /home/rrt/include/rrt/except.h /home/rrt/include/rrt/hash.h
Mit.o: /home/rrt/include/rrt/list.h /home/rrt/include/rrt/memory.h
Mit.o: /home/rrt/include/rrt/stream.h /home/rrt/include/rrt/string.h
Mit.o: Translate.h Translators.h /usr/include/alloca.h
Mit.o: /usr/include/bits/endian.h /usr/include/bits/local_lim.h
Mit.o: /usr/include/bits/posix1_lim.h /usr/include/bits/posix2_lim.h
Mit.o: /usr/include/bits/pthreadtypes.h /usr/include/bits/sched.h
Mit.o: /usr/include/bits/select.h /usr/include/bits/setjmp.h
Mit.o: /usr/include/bits/sigset.h /usr/include/bits/stdio_lim.h
Mit.o: /usr/include/bits/time.h /usr/include/bits/types.h
Mit.o: /usr/include/bits/waitflags.h /usr/include/bits/waitstatus.h
Mit.o: /usr/include/bits/wchar.h /usr/include/bits/wordsize.h
Mit.o: /usr/include/bits/xopen_lim.h /usr/include/endian.h
Mit.o: /usr/include/features.h /usr/include/_G_config.h /usr/include/gconv.h
Mit.o: /usr/include/gnu/stubs.h /usr/include/libio.h /usr/include/limits.h
Mit.o: /usr/include/linux/limits.h /usr/include/setjmp.h /usr/include/stdint.h
Mit.o: /usr/include/stdio.h /usr/include/stdlib.h /usr/include/string.h
Mit.o: /usr/include/sys/cdefs.h /usr/include/sys/select.h
Mit.o: /usr/include/sys/sysmacros.h /usr/include/sys/types.h
Mit.o: /usr/include/time.h /usr/include/wchar.h /usr/include/xlocale.h
Mit.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/limits.h
Mit.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stdarg.h
Mit.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h
Mit.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/syslimits.h
ObjToObj.o: /home/rrt/include/rrt/except.h /home/rrt/include/rrt/hash.h
ObjToObj.o: /home/rrt/include/rrt/list.h /home/rrt/include/rrt/memory.h
ObjToObj.o: ObjRead.c ObjWrite.c Translate.h /usr/include/alloca.h
ObjToObj.o: /usr/include/bits/endian.h /usr/include/bits/local_lim.h
ObjToObj.o: /usr/include/bits/posix1_lim.h /usr/include/bits/posix2_lim.h
ObjToObj.o: /usr/include/bits/pthreadtypes.h /usr/include/bits/sched.h
ObjToObj.o: /usr/include/bits/select.h /usr/include/bits/setjmp.h
ObjToObj.o: /usr/include/bits/sigset.h /usr/include/bits/stdio_lim.h
ObjToObj.o: /usr/include/bits/time.h /usr/include/bits/types.h
ObjToObj.o: /usr/include/bits/waitflags.h /usr/include/bits/waitstatus.h
ObjToObj.o: /usr/include/bits/wchar.h /usr/include/bits/wordsize.h
ObjToObj.o: /usr/include/bits/xopen_lim.h /usr/include/endian.h
ObjToObj.o: /usr/include/features.h /usr/include/gnu/stubs.h
ObjToObj.o: /usr/include/limits.h /usr/include/linux/limits.h
ObjToObj.o: /usr/include/setjmp.h /usr/include/stdint.h /usr/include/stdlib.h
ObjToObj.o: /usr/include/sys/cdefs.h /usr/include/sys/select.h
ObjToObj.o: /usr/include/sys/sysmacros.h /usr/include/sys/types.h
ObjToObj.o: /usr/include/time.h /usr/include/xlocale.h
ObjToObj.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/limits.h
ObjToObj.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stdarg.h
ObjToObj.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h
ObjToObj.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/syslimits.h
Translate.o: /home/rrt/include/rrt/except.h /home/rrt/include/rrt/hash.h
Translate.o: /home/rrt/include/rrt/list.h /home/rrt/include/rrt/memory.h
Translate.o: Translate.h /usr/include/alloca.h /usr/include/bits/endian.h
Translate.o: /usr/include/bits/local_lim.h /usr/include/bits/posix1_lim.h
Translate.o: /usr/include/bits/posix2_lim.h /usr/include/bits/pthreadtypes.h
Translate.o: /usr/include/bits/sched.h /usr/include/bits/select.h
Translate.o: /usr/include/bits/setjmp.h /usr/include/bits/sigset.h
Translate.o: /usr/include/bits/stdio_lim.h /usr/include/bits/time.h
Translate.o: /usr/include/bits/types.h /usr/include/bits/waitflags.h
Translate.o: /usr/include/bits/waitstatus.h /usr/include/bits/wchar.h
Translate.o: /usr/include/bits/wordsize.h /usr/include/bits/xopen_lim.h
Translate.o: /usr/include/endian.h /usr/include/features.h
Translate.o: /usr/include/gnu/stubs.h /usr/include/limits.h
Translate.o: /usr/include/linux/limits.h /usr/include/setjmp.h
Translate.o: /usr/include/stdint.h /usr/include/stdlib.h /usr/include/string.h
Translate.o: /usr/include/sys/cdefs.h /usr/include/sys/select.h
Translate.o: /usr/include/sys/sysmacros.h /usr/include/sys/types.h
Translate.o: /usr/include/time.h /usr/include/xlocale.h
Translate.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/limits.h
Translate.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stdarg.h
Translate.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h
Translate.o: /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/syslimits.h
