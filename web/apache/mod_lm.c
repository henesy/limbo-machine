#include "mod_lm.h"

static void register_hooks(apr_pool_t *p);
static int request_handler(request_rec *r);

module AP_MODULE_DECLARE_DATA mod_lm =
{
    STANDARD20_MODULE_STUFF,
    NULL,              /* create per-directory config structure */
    NULL,              /* merge per-directory config structures */
    NULL,              /* create per-server config structure */
    NULL,              /* merge per-server config structures */
    NULL,              /* command apr_table_t */
    register_hooks     /* register hooks */
};

static void register_hooks(apr_pool_t *p)
{
    ap_hook_handler(request_handler, NULL, NULL, APR_HOOK_MIDDLE);
}

static int request_handler(request_rec *r)
{
    if (strcmp(r->handler, "mod_lm"))
        return DECLINED;

    r->allowed |= (AP_METHOD_BIT << M_POST);
    r->allowed |= (AP_METHOD_BIT << M_GET);

    if (r->header_only)
        return OK;

    if (r->method_number == M_GET)
        return create_session(r);

    if (r->method_number != M_POST)
        return DECLINED;

    return tunnel(r);
}
