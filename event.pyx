#
# event.pyx
#
# libevent Python bindings
#
# Copyright (c) 2004 Dug Song <dugsong@monkey.org>
# Copyright (c) 2003 Martin Murray <murrayma@citi.umich.edu>
#
# $Id$

"""event library

This module provides a mechanism to execute a function when a
specific event on a file handle, file descriptor, or signal occurs,
or after a given time has passed.
"""

__author__ = ( 'Dug Song <dugsong@monkey.org>',
               'Martin Murray <mmurray@monkey.org>' )
__copyright__ = ( 'Copyright (c) 2004 Dug Song',
                  'Copyright (c) 2003 Martin Murray' )
__license__ = 'BSD'
__url__ = 'http://monkey.org/~dugsong/pyevent/'
__version__ = '0.2'

import sys

cdef extern from "Python.h":
    void  Py_INCREF(object o)
    void  Py_DECREF(object o)
    
ctypedef void (*event_handler)(int fd, short evtype, void *arg)
    
cdef extern from "event.h":
    struct timeval:
        unsigned int tv_sec
        unsigned int tv_usec
    
    struct event_t "event":
        int   ev_fd
        int   ev_flags
        void *ev_arg

    void event_init()
    void event_set(event_t *ev, int fd, short event,
                   event_handler handler, void *arg)
    void evtimer_set(event_t *ev, event_handler handler, void *arg)
    int  event_add(event_t *ev, timeval *tv)
    int  event_del(event_t *ev)
    int  event_dispatch()
    int  event_loop(int loop)
    int  event_pending(event_t *ev, short, timeval *tv)

    int EVLOOP_ONCE
    int EVLOOP_NONBLOCK

EV_TIMEOUT = 0x01
EV_READ    = 0x02
EV_WRITE   = 0x04
EV_SIGNAL  = 0x08
EV_PERSIST = 0x10

__event_exc = None

cdef int __event_inited

cdef int __event_sigcb():
    return -1

cdef void __event_handler(int fd, short evtype, void *arg):
    (<object>arg).__callback(evtype)

cdef void __simple_event_handler(int fd, short evtype, void *arg):
    (<object>arg).__simple_callback(evtype)

cdef class event:
    """event(callback, arg=None, evtype=0, handle=None) -> event object
    
    Create a new event object with a user callback.

    Arguments:

    callback -- user callback with (ev, handle, evtype, arg) prototype
                XXX - EV_SIGNAL events are always persistent
    arg      -- optional callback arguments
    evtype   -- bitmask of EV_READ or EV_WRITE, or EV_SIGNAL
    handle   -- for EV_READ or EV_WRITE, a file handle, descriptor, or socket
                for EV_SIGNAL, a signal number
    """
    cdef event_t ev
    cdef object handle, evtype, callback, args
    cdef float timeout
    cdef timeval tv

    def __init__(self, callback, arg=None, short evtype=0, handle=-1,
                 simple=0):
        cdef event_handler handler
        
        self.callback = callback
        self.args = arg
        self.evtype = evtype
        self.handle = handle
        if simple:
            handler = __simple_event_handler
        else:
            handler = __event_handler
        if evtype == 0 and not handle:
            evtimer_set(&self.ev, handler, <void *>self)
        elif evtype == EV_SIGNAL:
            evtype = evtype | EV_PERSIST
            event_set(&self.ev, handle, evtype, handler, <void *>self)
        else:
            if type(handle) != int:
                handle = handle.fileno()
            event_set(&self.ev, handle, evtype, handler, <void *>self)

    def __simple_callback(self, short evtype):
        cdef extern int event_gotsig
        cdef extern int (*event_sigcb)()
        global __event_exc
        try:
            if self.callback(*self.args) != None:
                if self.tv.tv_sec or self.tv.tv_usec:
                    event_add(&self.ev, &self.tv)
                else:
                    event_add(&self.ev, NULL)
        except:
            __event_exc = sys.exc_info()
            event_sigcb = __event_sigcb
            event_gotsig = 1
        if not event_pending(&self.ev, EV_READ|EV_WRITE|EV_SIGNAL|EV_TIMEOUT, NULL):
            Py_DECREF(self)
    
    def __callback(self, short evtype):
        cdef extern int event_gotsig
        cdef extern int (*event_sigcb)()
        global __event_exc
        try:
            self.callback(self, self.handle, evtype, self.args)
        except:
            __event_exc = sys.exc_info()
            event_sigcb = __event_sigcb
            event_gotsig = 1
        if not event_pending(&self.ev, EV_READ|EV_WRITE|EV_SIGNAL|EV_TIMEOUT, NULL):
            Py_DECREF(self)

    def add(self, float timeout=-1):
        """Add event to be executed after an optional timeout.

        Arguments:
        
        timeout -- seconds after which the event will be executed
        """
        if not event_pending(&self.ev, EV_READ|EV_WRITE|EV_SIGNAL|EV_TIMEOUT,
                             NULL):
            Py_INCREF(self)
        self.timeout = timeout
        if timeout >= 0.0:
            self.tv.tv_sec = <long>timeout
            self.tv.tv_usec = (timeout - <float>self.tv.tv_sec) * 1000000.0
            event_add(&self.ev, &self.tv)
        else:
            self.tv.tv_sec = self.tv.tv_usec = 0
            event_add(&self.ev, NULL)

    def pending(self):
        """Return 1 if the event is scheduled to run, or else 0."""
        return event_pending(&self.ev, EV_TIMEOUT|EV_SIGNAL|EV_READ|EV_WRITE, NULL)
    
    def delete(self):
        """Remove event from the event queue."""
        if self.pending():
            event_del(&self.ev)
            Py_DECREF(self)
    
    def __dealloc__(self):
        self.delete()
    
    def __repr__(self):
        return '<event flags=0x%x, handle=%s, callback=%s, arg=%s>' % \
               (self.ev.ev_flags, self.handle, self.callback, self.args)

cdef class read(event):
    """read(handle, callback, *args) -> event object
    
    Simplified event interface:
    Create a new read event, and add it to the event queue.
    
    Arguments:

    handle   -- file handle, descriptor, or socket
    callback -- user callback with (*args) prototype, which can return
                a non-None value to be rescheduled
    *args    -- optional callback arguments
    """
    def __init__(self, handle, callback, *args):
        event.__init__(self, callback, args, EV_READ, handle, simple=1)
        self.add()

cdef class write(event):
    """write(handle, callback, *args) -> event object

    Simplified event interface:
    Create a new write event, and add it to the event queue.
    
    Arguments:

    handle   -- file handle, descriptor, or socket
    callback -- user callback with (*args) prototype, which can return
                a non-None value to be rescheduled
    *args    -- optional callback arguments
    """
    def __init__(self, handle, callback, *args):
        event.__init__(self, callback, args, EV_WRITE, handle, simple=1)
        self.add()
        
cdef class signal(event):
    """signal(sig, callback, *args) -> event object

    Simplified event interface:
    Create a new signal event, and add it to the event queue.

    Arguments:

    sig      -- signal number
    callback -- user callback with (*args) prototype, which can return
                a non-None value to be rescheduled
    *args    -- optional callback arguments
    """
    def __init__(self, sig, callback, *args):
        event.__init__(self, callback, args, EV_SIGNAL, sig, simple=1)
        self.add()

cdef class timeout(event):
    """timeout(timeout, callback, *args) -> event object

    Simplified event interface:
    Create a new timer event, and add it to the event queue.

    Arguments:

    timeout  -- event timeout in seconds
    callback -- user callback with (*args) prototype, which can return
                a non-None value to be rescheduled
    *args    -- optional callback arguments
    """
    def __init__(self, secs, callback, *args):
        event.__init__(self, callback, args, simple=1)
        self.add(secs)

def init():
    """Initialize event queue."""
    if not __event_inited:
        event_init()
        __event_inited = 1

def dispatch():
    """Dispatch all events on the event queue."""
    global __event_exc
    event_dispatch()
    if __event_exc:
        raise __event_exc[0], __event_exc[1], __event_exc[2]

def loop(nonblock=False):
    """Dispatch all pending events on queue in a single pass."""
    cdef int flags
    flags = EVLOOP_ONCE
    if nonblock:
        flags = EVLOOP_ONCE|EVLOOP_NONBLOCK
    event_loop(flags)

def abort():
    """Abort event dispatch loop."""
    cdef extern int event_gotsig
    cdef extern int (*event_sigcb)()
    event_sigcb = __event_sigcb
    event_gotsig = 1

if not __event_inited:
    # XXX - make sure event queue is always initialized.
    # XXX XXX - if we do this here, EVENT_NOXXX need to be set before import!
    event_init()
