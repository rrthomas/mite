# Top-level Makefile for Mite
# (c) Reuben Thomas 1999


MITE = .


all: mit doc

mit:
	cd src; $(MAKE) all

doc:
	cd doc; $(MAKE) all

dist: all dist-clean
	cd ..
	rm -f mite.zip
	zip -qr mite.zip mite

clean:
	cd src; $(MAKE) $@
	cd doc; $(MAKE) $@

dist-clean:
	cd src; $(MAKE) $@
	cd doc; $(MAKE) $@
