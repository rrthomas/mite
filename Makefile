# Makefile for Mite
# (c) Reuben Thomas 1999

CC = gcc
WARN = -Wall -W -Wundef -Wpointer-arith -Wbad-function-cast -Wcast-qual \
       -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
CFLAGS = -ansi -pedantic $(WARN) -g -O2 -fomit-frame-pointer 
LDFLAGS = -lm

HEVEA_FLAGS= -I texmf

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

SRCS=mit.c translate.c objToObj.c asmToObj.c except.c list.c hash.c flen.c
OBJS=mit.o translate.o objToObj.o asmToObj.o except.o list.o hash.o flen.o


all: mit

dist: mite.pdf mit.pdf iface.pdf
	rm -f mite.zip
	zip -qr mite.zip Makefile README *.pdf mite.tex *.w \
		*.txt mit.* *.c *.h

mit: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

mite.h: iface.w
	$(NUWEB.prg) iface.w

insts.c: insts.gperf
	gperf -L ANSI-C -N findInst -t -k 1,2,'$$' $< > $@

endian.h: endian.c
	$(CC) -o endian endian.c
	./endian > $@

doc: mite.dvi mit.dvi iface.dvi

depend:
	makedepend -I${HOME}/include -- $(CFLAGS) -- $(SRCS)

clean:
	rm -f $(OBJS)
	lmk -clean mite.tex # mit.w iface.w
