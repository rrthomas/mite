# Makefile for mit
# (c) Reuben Thomas 1999


MITE_TOP = ..


# Programs and options

CC = gcc
WARN = -Wall -W -Wundef -Wpointer-arith -Wbad-function-cast -Wcast-qual \
       -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
COPTS = -ansi -pedantic -g # -O2 -fomit-frame-pointer
CFLAGS = $(COPTS) $(WARN)
LDFLAGS = -lm

RUNLUA = lua -f $(MITE_TOP)/script/runLua.lua $(MITE_TOP)


# Source files

include translator.make
TRANS_OBJS = $(patsubst %.c,%.o,$(TRANS_SRCS))
SRCS = mit.c translate.c except.c list.c hash.c flen.c insts.c


# Generated files

OBJS = $(patsubst %.c,%.o,$(SRCS) $(TRANS_SRCS))
GEN_SRCS = instEnum.h insts.gperf insts.c endian.h
PROGS = mit endian


# Top-level targets

all: mit

depend: $(SRCS) $(GEN_SRCS) $(TRANS_SRCS)
	mkdep -p $(CFLAGS) $(SRCS) $(TRANS_SRCS)

clean:
	rm -f $(OBJS)

dist-clean: clean
	rm -f $(PROGS) $(GEN_SRCS) $(TRANS_SRCS)


# File dependencies

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

insts.gperf translate.h: $(MITE_TOP)/spec.lua procSpec.lua
	$(RUNLUA) procSpec.lua
	touch translate.h


# Include dependencies

include .depend
