#!/usr/bin/env python
#
# $Id$

from distutils.core import setup, Extension
import glob, os, sys

if glob.glob('/usr/lib/libevent.*'):
    print 'found system libevent for', sys.platform
    event = Extension(name='event',
                       sources=[ 'event.c' ],
                       libraries=[ 'event' ])
elif glob.glob('%s/lib/libevent.*' % sys.prefix):
    print 'found installed libevent in', sys.prefix
    event = Extension(name='event',
                       sources=[ 'event.c' ],
                       include_dirs=[ '%s/include' % sys.prefix ],
                       library_dirs=[ '%s/lib' % sys.prefix ],
                       libraries=[ 'event' ])
else:
    l = glob.glob('../libevent*')
    for dir in l:
        if os.path.isdir(dir):
            print 'found libevent build directory', dir
            event = Extension(name='event',
                              sources=[ 'event.c' ],
                              include_dirs = [ dir ],
                              extra_objects = glob.glob('%s/*.o' % dir))
            break
    else:
        if not l:
            raise "couldn't find libevent installation or build directory"

setup(name='event',
      version='0.2',
      author='Dug Song, Martin Murray',
      url='http://monkey.org/~dugsong/pyevent',
      description='event library',
      ext_modules = [ event ])
