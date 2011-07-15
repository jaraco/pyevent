#!/usr/bin/env python
#
# $Id$

import distutils.core
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
        print 'found libevent build directory', ev_dir
    except StopIteration:
        raise RuntimeError("couldn't find libevent installation or build directory")
        best = '../libevent'
    return best

def get_extension():
    event = distutils.core.Extension(name='event', sources=['event.c'])
    if glob.glob('/usr/lib/libevent.*'):
        print 'found system libevent for', sys.platform
        event.libraries=['event']
        return event
    elif glob.glob('%s/lib/libevent.*' % sys.prefix):
        print 'found installed libevent in', sys.prefix
        event.include_dirs=['%s/include' % sys.prefix]
        event.library_dirs=['%s/lib' % sys.prefix]
        event.libraries=['event']
        return event

    ev_dir = get_best_build_dir()
    event.include_dirs.append(ev_dir)

    if sys.platform == 'win32':
        event.include_dirs.extend([
            '%(ev_dir)s/WIN32-Code' % vars(),
            '%(ev_dir)s/compat' % vars()
        ])
        sources = ['WIN32-Code/misc.c', 'WIN32-Code/win32.c', 'log.c', 'event.c']
        sources = [os.path.join(ev_dir, source) for source in sources]
        event.sources.extend(sources)
        event.extra_compile_args.extend(['-DWIN32', '-DHAVE_CONFIG_H'])
        event.libraries.append('wsock32')
    else:
        event.extra_objects.extend(glob.glob('%(ev_dir)s/*.o' % vars()))

    return event

setup_params = dict(
    name='event',
    version='0.4',
    author='Dug Song',
    author_email='dugsong@monkey.org',
    url='http://monkey.org/~dugsong/pyevent/',
    description='event library',
    long_description="""This module provides a mechanism to execute a function when a specific event on a file handle, file descriptor, or signal occurs, or after a given time has passed.""",
    license='BSD',
    download_url='http://monkey.org/~dugsong/pyevent/',
    ext_modules = [get_extension()],
)

if __name__ == '__main__':
    distutils.core.setup(**setup_params)
