# Makefile for Mite documentation
# (c) Reuben Thomas 1999, 2014


MITE_TOP = ..


# Programs and options

RUNLUA = lua $(MITE_TOP)/script/runLua.lua $(MITE_TOP)


# Suffix rules

%.pdf: %.tex
	pdflatex $<
	bibtex $*
	pdflatex $<
	pdflatex $<

%.html: %.tex
	hevea $(HEVEA_FLAGS) sym.hva $<


# Source files

DOCS = mite.pdf iface.pdf mit.pdf
TEX_TABLES = instLab.tex instComp.tex instData.tex instCcall.tex instOpcode.tex


# Top-level targets

all: $(DOCS)

clean:
	rm -f *.log *.aux *.blg *.bbl

dist-clean:
	rm -f *.html *.pdf $(TEX_TABLES)


# File dependencies

$(TEX_TABLES): $(MITE_TOP)/spec.lua procSpec.lua
	$(RUNLUA) procSpec.lua
	touch mite.tex

mite.pdf: $(TEX_TABLES)
