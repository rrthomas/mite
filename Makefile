# Makefile for Mite
# (c) Reuben Thomas 1999


# Programs and options

CC = gcc
WARN = -Wall -W -Wundef -Wpointer-arith -Wbad-function-cast -Wcast-qual \
       -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
COPTS = -ansi -pedantic -g # -O2 -fomit-frame-pointer 
CFLAGS = $(COPTS) $(WARN)
LDFLAGS = -lm
HEVEA_FLAGS = -I texmf


# Suffix rules

.SUFFIXES: .tex .dvi .ps .pdf .html
.tex.dvi:
	latex $<
	bibtex $*
	latex $<
	latex $<
.dvi.ps:
	dvips $<
.ps.pdf:
	ps2pdf $<
.tex.html:
	hevea $(HEVEA_FLAGS) sym.hva package.hva ctable.sty $<


# Source files

TRANS_SRC = asmToObj.c objToAsm.c
TRANS_OBJ = asmToObj.o objToAsm.o
SRCS = mit.c translate.c except.c list.c hash.c flen.c insts.c $(TRANS_SRC)
OBJS = mit.o translate.o except.o list.o hash.o flen.o insts.o $(TRANS_OBJ)

DOCS = README TODO MANIFESTO mite.pdf iface.pdf
TEX_TABLES = instLab.tex instComp.tex instData.tex instOpcode.tex

# Top-level targets

all: mit

doc: $(DOCS)

depend: .depend $(SRCS)


dist: $(DOCS)
	rm -f mite.zip
	zip -qr mite.zip Makefile README ToDo Manifesto *.pdf *.tex *.c *.h

clean:
	rm -f $(OBJS) *.log *.aux *.blg *.bbl


# File dependencies

.depend: $(SRCS)
	mkdep -p $(CFLAGS) $(SRCS)

mit: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

# avoid spurious warnings when compiling gperf output
insts.o:
	$(CC) -c $(COPTS) -o $@ $<

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
