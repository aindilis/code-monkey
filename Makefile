#!/usr/bin/make -f

SYSNAME=code-monkey

configure: configure-stamp

configure-stamp:
	touch configure-stamp

build: build-stamp

build-stamp: configure-stamp 
	touch build-stamp

clean:
	(find . | grep '~$$' | xargs rm) || true

etags:
	find . | grep -E '(pm|pl)$$' | etags -

install:


.PHONY: build clean install configure
