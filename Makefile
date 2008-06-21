
PYTHON	= DISTUTILS_USE_SDK=1 MSSdk=1 python2.5
PKGDIR	= pyevent-`egrep version setup.py | cut -f2 -d"'"`
URL	= `egrep url setup.py | cut -f2 -d"'"`

all: event.c
	$(PYTHON) setup.py build

event.c: event.pyx bufferevent.pxi evdns.pxi evhttp.pxi simple.pxi
	pyrexc event.pyx

install:
	$(PYTHON) setup.py install

test:
	$(PYTHON) test.py

doc:
	epydoc -o doc -n event -u http://monkey.org/~dugsong/pyevent/ --docformat=plaintext event

pkg_win32:
	$(PYTHON) setup.py bdist_wininst

pkg_osx:
	bdist_mpkg --readme=README --license=LICENSE
	mv dist $(PKGDIR)
	hdiutil create -srcfolder $(PKGDIR) $(PKGDIR).dmg
	mv $(PKGDIR) dist

clean:
	rm -rf build dist

cleandir distclean: clean
	rm -f *.c *~
