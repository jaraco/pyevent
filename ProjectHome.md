Python extension module for [libevent](http://monkey.org/~provos/libevent)

example use:
```
>>> import event
>>> def sig_cb(a, b, c):
...     print a, b, c
...     event.abort()
... 
>>> def time_cb(msg):
...     print msg
...     return True
... 
>>> event.timeout(5, time_cb, 'hello world')
<event flags=0x81, handle=-1, callback=<function time_cb at 0x3c0c51b4>, arg=('hello world',)>
>>> event.signal(2, sig_cb, 1, [1,2], 345)
<event flags=0x1084, handle=2, callback=<function sig_cb at 0x3c0c5144>, arg=(1, [1, 2], 345)>
>>> event.dispatch()
hello world
hello world
hello world
^C1 [1, 2] 345
>>>
```