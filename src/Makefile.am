# Source Makefile.am

#SUBDIRS = tests

RUNLUA = lua $(top_srcdir)/script/runLua.lua $(top_srcdir)

AM_CPPFLAGS = -I$(top_builddir)/lib -I$(top_srcdir)/lib

noinst_LIBRARIES = libmite.a
libmite_a_SOURCES = buffer.h const.h except.h except.c hash.h hash.c file.h file.c insts.h list.h list.c translate.h translate.c types.h util.h
nodist_libmite_a_SOURCES = $(GEN_SRCS)

bin_PROGRAMS = mit

GEN_SRCS = instEnum.h insts.gperf insts.c excEnum.h excMsg.h \
    translators.c translators.h

except.o: $(GEN_SRCS)

mit_LDADD = libmite.a $(top_builddir)/lib/libgnu.a -lm
mit_SOURCES = mit.c

LUA_SRCS = procSpec.lua asmRead.lua asmWrite.lua objRead.lua objWrite.lua \
	interpWrite.lua runWrite.lua interpDebug.lua mkTrans.lua \
	transList.lua except.lua mkExcept.lua

EXTRA_DIST = $(LUA_SRCS)

# # avoid spurious warnings when compiling gperf output
# insts.o: insts.c
#	$(CC) -c $(COPTS) -o $@ $<

insts.c: insts.gperf
	gperf -L ANSI-C -N findInst -t -k 1,2,'$$' $< > $@

insts.gperf translate.h instEnum.h: $(top_srcdir)/spec.lua procSpec.lua
	$(RUNLUA) $(srcdir)/procSpec.lua
	touch $(srcdir)/translate.h

excEnum.h excMsg.h: except.lua mkExcept.lua
	$(RUNLUA) $(srcdir)/mkExcept.lua $(srcdir)/except.lua
	touch $(srcdir)/except.h

# Translators; FIXME: this rules should be automated and removed
translators.h translators.c: asmRead.lua asmWrite.lua objRead.lua objWrite.lua \
    interpWrite.lua runWrite.lua interpDebug.lua mkTrans.lua \
    transList.lua
	$(RUNLUA) $(srcdir)/mkTrans.lua $(srcdir)/transList.lua translators

clean-local:
	rm -f $(GEN_SRCS)

check-local: libmite.a

CLOC = cloc --force-lang="C",h

loc:
	$(CLOC) $(libmite_a_SOURCES) $(mit_SOURCES) $(LUA_SRCS)
