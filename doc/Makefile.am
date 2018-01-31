# Docs Makefile.am

# FIXME: can we put this into the top-level Makefile.am?
RUNLUA = lua $(top_srcdir)/script/runLua.lua $(top_srcdir)

TEX_TABLES = instLab.tex instComp.tex instData.tex instCcall.tex instOpcode.tex

LATEX_SRCS = \
	$(srcdir)/mite.tex \
	$(srcdir)/iface.tex \
	$(srcdir)/mit.tex

LATEX_PDFS = \
	$(builddir)/mite.pdf \
	$(builddir)/iface.pdf \
	$(builddir)/mit.pdf

GEN_SRCS = opTypes.tex

$(TEX_TABLES): $(top_srcdir)/spec.lua procSpec.lua
	$(RUNLUA) $(srcdir)/procSpec.lua
	touch $(srcdir)/mite.tex

mite.pdf: $(TEX_TABLES)

EXTRA_DIST = $(LATEX_SRCS) $(LATEX_PDFS) procSpec.lua mite.bib

DISTCLEANFILES = $(LATEX_PDFS)

.tex.pdf:
	$(LATEXMK) -pdf $<

.tex.html:
	hevea $(HEVEA_FLAGS) sym.hva $<


all: pdf

pdf-local: $(LATEX_PDFS)

clean-local:
	$(LATEXMK) -C
	rm -f $(TEX_TABLES) $(GEN_SRCS)
