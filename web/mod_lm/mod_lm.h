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

/** mod_lm_session.c */
extern int create_session(request_rec *r);

/** mod_lm_tunnel.c */
extern int tunnel(request_rec *r);
