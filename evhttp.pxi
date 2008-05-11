
cdef extern from "event.h":
    evbuffer *evbuffer_new()
    int       evbuffer_add(evbuffer *eb, void *data, int len)
    void      evbuffer_free(evbuffer *eb)

HTTP_OK		= 200
HTTP_NOCONTENT  = 204

cdef extern from "evhttp.h":
    struct evhttp_t "evhttp":
        int __xxx
    struct evhttp_request:
        char	*remote_host
        short	remote_port
        int	req_kind
        int	cmd_type
        char	*uri
        char	major
        char	minor
        int	response_code
        char	*response_code_line
        evbuffer *input_buffer

    ctypedef void (*evhttp_handler)(evhttp_request *, void *arg)

    evhttp_t *evhttp_start(char *address, unsigned short port)
    void     evhttp_set_cb(evhttp_t *http, char *uri,
                           evhttp_handler handler, void *arg)
    void     evhttp_set_gencb(evhttp_t *http,
                              evhttp_handler handler, void *arg)
    void     evhttp_del_cb(evhttp_t *http, char *uri)
    void     evhttp_set_timeout(evhttp_t *http, int secs)
    void     evhttp_send_reply(evhttp_request *req, int code, char *reason,
                               evbuffer *databuf)
    void     evhttp_send_error(evhttp_request *req, int error, char *reason)
    void     evhttp_free(evhttp_t *http)

cdef void __evhttp_callback(evhttp_request *req, void *arg):
    global __event_exc
    
    # Stuff request into dict
    reqd = {}
    reqd['uri'] = req.uri
    
    (cb, key) = (<object>arg)
    try:
        cb(reqd)
    except:
        __event_exc = sys.exc_info()
        __event_abort()
                    
cdef class evhttp:
    """Instantiate new webserver.
    """
    cdef evhttp_t *_http
    cdef object __callbacks
    
    def __init__(self, address='0.0.0.0', port=80):
        self._http = evhttp_start(address, port)
        if self._http == NULL:
            raise OSError, 'bind'	# XXX - libevent should event_warn
        self.__callbacks = {}

    def __setitem__(self, key, cb):
        if key is None:
            self.__callbacks[key] = (cb, key)
            evhttp_set_gencb(self._http, __evhttp_callback,
                             <void *>self.__callbacks[key])
        else:
            if key in self.callbacks:
                evhttp_del_cb(self._http, key)
            self.__callbacks[key] = (cb, key)
            evhttp_set_cb(self._http, key, __evhttp_callback,
                          <void *>self.__callbacks[key])
    
    def __dealloc__(self):
        if self._http != NULL:
            evhttp_free(self._http)
        self._http = NULL

