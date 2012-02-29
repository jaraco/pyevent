#!/usr/bin/env python
#
# $Id$

try:
    from setuptools import setup, Extension
except ImportError:
    from distutils.core import setup, Extension
import glob
import os
import sys
import warnings

LIBEVENT_BUILD_DIR = '../libevent*'

def get_best_build_dir():
    candidates = reversed(glob.glob(LIBEVENT_BUILD_DIR))
    matches = (dir for dir in candidates if os.path.isdir(dir))
    try:
        best = next(matches)
        print 'found libevent build directory', best
    except StopIteration:
        warnings.warn("Could not find libevent")
        best = '../libevent'
    return best

def get_extension():
    event = Extension(name='event', sources=['event.c'])
    if glob.glob('/usr/lib/libevent.*'):
        print 'found system libevent for', sys.platform
        event.libraries = ['event']
        return event
    for prefix in (sys.prefix, "/usr/local", "/opt/local"):
        if glob.glob("%s/lib/libevent.*" % prefix):
            print 'found installed libevent in', prefix
            event.include_dirs = ['%s/include' % prefix]
            event.library_dirs = ['%s/lib' % prefix]
            event.libraries = ['event']
            return event

    ev_dir = get_best_build_dir()
    event.include_dirs.append(ev_dir)

    if sys.platform == 'win32':
        event.include_dirs.extend([
            '%(ev_dir)s/WIN32-Code' % vars(),
            '%(ev_dir)s/compat' % vars()
        ])
        sources = ['WIN32-Code/win32.c', 'log.c', 'event.c']
        sources = [os.path.join(ev_dir, source) for source in sources]
        event.sources.extend(sources)
        event.extra_compile_args.extend(['-DWIN32', '-DHAVE_CONFIG_H'])
        event.libraries.append('wsock32')
    else:
        event.extra_objects.extend(glob.glob('%(ev_dir)s/*.o' % vars()))

    return event

setup_params = dict(
    name='event',
    version='0.4.2',
    author='Dug Song',
    author_email='dugsong@monkey.org',
    maintainer='Jason R. Coombs',
    maintainer_email='jaraco@jaraco.com',
    url='https://bitbucket.org/jaraco/pyevent',
    description='event library',
    long_description="""This module provides a mechanism to execute a function when a specific event on a file handle, file descriptor, or signal occurs, or after a given time has passed.""",
    license='BSD',
    ext_modules = [get_extension()],
)

if __name__ == '__main__':
    setup(**setup_params)
