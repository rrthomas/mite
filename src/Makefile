# Makefile for mit
# (c) Reuben Thomas 1999


MITE_TOP = ..


# Programs and options

CC = gcc
WARN = -Wall -W -Wundef -Wpointer-arith -Wbad-function-cast -Wcast-qual \
    -Wcast-align -Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes
COPTS = -ansi -pedantic -g # -O2 -fomit-frame-pointer
CFLAGS = $(COPTS) $(WARN)
LDFLAGS = -lm # -s

RUNLUA = lua -f $(MITE_TOP)/script/runLua.lua $(MITE_TOP)


# Source files

SRCS = mit.c except.c hash.c file.c insts.c translators.c


# Generated files

OBJS = $(patsubst %.c,%.o,$(SRCS))
GEN_SRCS = instEnum.h insts.gperf insts.c endian.h excEnum.h excMsg.h \
    translators.h translators.c
PROGS = mit endian


# Top-level targets

all: mit

depend: $(SRCS) $(GEN_SRCS)
	mkdep -p $(CFLAGS) $(SRCS)

clean:
	rm -f $(OBJS)

veryclean dist-clean: clean
	rm -f $(PROGS) $(GEN_SRCS)


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

insts.gperf translate.h instEnum.h: $(MITE_TOP)/spec.lua procSpec.lua
	$(RUNLUA) procSpec.lua
	touch translate.h

mit.o: translators.c

except.h: excEnum.h

except.c: excMsg.h

excEnum.h excMsg.h: except.lua mkExcept.lua
	$(RUNLUA) mkExcept.lua except.lua
	touch except.h


# Translators; this rule should be automated and removed
translators.c: asmRead.lua asmWrite.lua objRead.lua objWrite.lua \
    interpWrite.lua runWrite.lua mkTrans.lua
	$(RUNLUA) mkTrans.lua transList.lua $*


# Include dependencies

include .depend
