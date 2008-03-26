#include "mod_lm.h"

extern int create_session(request_rec *r)
{
    ap_set_content_type(r, "text/html");
    ap_rputs(DOCTYPE_HTML_4_0T, r);
    ap_rputs("<html><body><h3>Limbo Machine Tunnel</hr></body></html>", r);

    return OK;
}
