# Makefile for Mite documentation
# (c) Reuben Thomas 1999


MITE_TOP = ..


# Programs and options

HEVEA_FLAGS = -I texmf


# Suffix rules

.SUFFIXES: .tex .dvi .ps .pdf .html

.tex.dvi:
	latex $<
#	bibtex $*
#	latex $<
	latex $<

.dvi.ps:
	dvips $<

.ps.pdf:
	ps2pdf $<

.tex.html:
	hevea $(HEVEA_FLAGS) sym.hva $<


# Source files

DOCS = mite.pdf iface.pdf mit.pdf
TEX_TABLES = instLab.tex instComp.tex instData.tex instOpcode.tex


# Top-level targets

all: $(DOCS)

clean:
	rm -f *.log *.aux *.blg *.bbl

dist-clean:
	rm -f *.dvi *.html *.ps *.pdf $(TEX_TABLES)


# File dependencies

$(TEX_TABLES): $(MITE_TOP)/spec.lua procSpec.lua
	lua -f procSpec.lua $(MITE_TOP)
	touch mite.tex

mite.tex: $(TEX_TABLES)
