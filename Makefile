# Makefile for Mite
# (c) Reuben Thomas 1999


# Programs and options

CC = gcc
WARN = -Wall -W -Wundef -Wpointer-arith -Wbad-function-cast -Wcast-qual \
       -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
CFLAGS = -ansi -pedantic $(WARN) -g # -O2 -fomit-frame-pointer 
LDFLAGS = -lm
HEVEA_FLAGS= -I texmf


# Suffix rules

.SUFFIXES: .tex .dvi .ps .pdf .html
.tex.dvi:
	lmk -q -co $<
.dvi.ps:
	dvips $<
.ps.pdf:
	ps2pdf $<
.tex.html:
	hevea $(HEVEA_FLAGS) sym.hva package.hva ctable.sty $<


# Source files

TRANS_SRC = objToObj.c asmToAsm.c asmToObj.c
TRANS_OBJ = objToObj.o asmToAsm.o asmToObj.o
SRCS = mit.c translate.c except.c list.c hash.c flen.c $(TRANS_SRC)
OBJS = mit.o translate.o except.o list.o hash.o flen.o $(TRANS_OBJ)

DOCS = README TODO Manifesto mite.pdf mit.pdf iface.pdf
TEX_TABLES = instLab.tex instComp.tex instData.tex instOpcode.tex

# Top-level targets

all: mit

doc: $(DOCS)

depend: .depend $(SRCS)


dist: $(DOCS)
	rm -f mite.zip
	zip -qr mite.zip Makefile README ToDo Manifesto *.pdf *.tex *.c *.h

clean:
	rm -f $(OBJS)
	lmk -clean mite.tex mit.tex iface.tex


# File dependencies

.depend: $(SRCS)
	mkdep -p $(CFLAGS) $(SRCS)

mit: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

insts.c: insts.gperf
	gperf -L ANSI-C -N findInst -t -k 1,2,'$$' $< > $@

endian.h: endian.c
	$(CC) -o endian endian.c
	./endian > $@

insts.gperf translate.h $(TEX_TABLES): insts.lua mkinsts.lua
	lua mkinsts.lua
	touch mite.tex

mite.tex: $(TEX_TABLES)


# Include dependencies

include .depend
