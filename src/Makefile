# Makefile for mit
# (c) Reuben Thomas 1999


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


# Top-level targets

all: mit

depend: .depend $(SRCS)


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

insts.gperf translate.h: $(MITE)/spec/insts.lua mkinsts.lua
	lua mkinsts.lua $(MITE)/spec/insts.lua


# Include dependencies

include .depend
