# Makefile for Mite documentation
# (c) Reuben Thomas 1999


# Programs and options

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
	hevea $(HEVEA_FLAGS) sym.hva $<


# Source files

DOCS = README TODO MANIFESTO mite.pdf iface.pdf
TEX_TABLES = instLab.tex instComp.tex instData.tex instOpcode.tex


# Top-level targets

all: $(DOCS)


# File dependencies

$(TEX_TABLES): $(MITE)/spec/insts.lua mkinsts.lua
	lua mkinsts.lua $(MITE)/spec/insts.lua
	touch mite.tex

mite.tex: $(TEX_TABLES)
