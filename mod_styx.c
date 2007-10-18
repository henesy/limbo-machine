#include "apr_strings.h"
#include "apr_network_io.h"
#include "ap_config.h"
#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "util_script.h"
#include "http_main.h"
#include "http_request.h"

#include "mod_core.h"

static int styx_handler(request_rec *r)
{
    if(strcmp(r->handler, "styx"))
        return DECLINED;

//    r->allowed |= (AP_METHOD_BIT << M_POST);
//    if (r->method_number != M_POST)
//        return DECLINED;

    r->allowed |= (AP_METHOD_BIT << M_GET);
    if (r->method_number != M_GET)
        return DECLINED;

    ap_set_content_type(r, "text/html");
    if (r->header_only)
        return OK;

    ap_rputs(DOCTYPE_HTML_3_2, r);
    ap_rputs("<html><body>styx</body></html>\n", r);

    /*
    apr_socket_t *s;
    apr_status_t res = apr_socket_create(
            &s, APR_INET, SOCK_STREAM, APR_PROTO_TCP, r->pool);

    apr_sockaddr_t *svc = styx_get_service();
    res = apr_socket_connect(s, svc);
    
    char *Tmsg;
    int Tlen = styx_decode(r, &Tmsg);
    res = apr_socket_send(s, Tmsg, Tlen);

    char *Rmsg;
    int Rlen = styx_encode(s, &Rmsg);
    ap_rputs(Rmsg, Rmsg, Rlen);
    */

    return OK;
}

/*
static const apr_sockaddr_t* styx_get_service()
{
    apr_sockaddr_t *svc;
    arp_status_t res = apr_sockaddr_info_get(
            svc, "localhost", APR_INET, 7777, APR_IPV4_ADDR_OK, r->pool);

    return svc;
}

static const int styx_decode(request_rec *r, char** msg)
{
}

static const int styx_encode(apr_pool_t *p, apr_socket_t *s, char** msg)
{
    char len[4]; // = apr_pcalloc(r->pool, 4);
    apr_status_t res = apr_socket_recv(s, len, 4);

    int msg_len = unpack32(len);
    char *msg = apr_pcalloc(p, msg_len);
    res = apr_socket_recv(s, msg, msg_len);

    return msg_len;
}

*/

static void register_hooks(apr_pool_t *p)
{
    ap_hook_handler(styx_handler, NULL, NULL, APR_HOOK_MIDDLE);
}

module AP_MODULE_DECLARE_DATA styx_module =
{
    STANDARD20_MODULE_STUFF,
    NULL,              /* create per-directory config structure */
    NULL,              /* merge per-directory config structures */
    NULL,              /* create per-server config structure */
    NULL,              /* merge per-server config structures */
    NULL,              /* command apr_table_t */
    register_hooks     /* register hooks */
};
