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


# Source files

TRANS_SRC = asmToObj.c objToAsm.c
TRANS_OBJ = asmToObj.o objToAsm.o
SRCS = mit.c translate.c except.c list.c hash.c flen.c insts.c $(TRANS_SRC)
OBJS = mit.o translate.o except.o list.o hash.o flen.o insts.o $(TRANS_OBJ)
GEN_SRCS = opToTypes.c opEnum.h insts.gperf insts.c endian.h
PROGS = mit endian

# Top-level targets

all: mit

depend: .depend

clean:
	rm -f $(OBJS)

dist-clean:
	rm -f $(PROGS) $(GEN_SRCS)

# File dependencies

.depend: $(SRCS) $(GEN_SRCS)
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

insts.gperf translate.h: $(MITE_TOP)/spec.lua procSpec.lua
	lua -f procSpec.lua $(MITE_TOP)
	touch translate.h


# Include dependencies

include .depend
