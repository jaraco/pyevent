
all: event.c
	python setup.py build

event.c: event.pyx
	pyrexc event.pyx

install:
	python setup.py install

test:
	python test.py

clean:
	rm -rf build

cleandir distclean: clean
	rm -f *.c *~
