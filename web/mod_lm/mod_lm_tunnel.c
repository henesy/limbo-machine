#include "mod_lm.h"

#define MAX_MSG_SIZE 8192

typedef struct lm_msg_t {
    int size;
    char *data;
} msg_t;

static int read_msg(request_rec *r, msg_t **msg);
static int write_msg(request_rec *r, msg_t *msg);
static int exchange(request_rec *r, msg_t *tmsg, msg_t **rmsg);

extern int tunnel(request_rec *r)
{
    int rv;
    msg_t *rmsg;
    msg_t *tmsg;

    if ((rv = read_msg(r, &tmsg)) != OK)
        return rv;

    if ((rv = exchange(r, tmsg, &rmsg)) != OK)
        return rv;

    if ((rv = write_msg(r, rmsg)) != OK)
        return rv;

    return OK;
}

static msg_t* decode(request_rec *r, msg_t *msg);
static msg_t* encode(request_rec *r, msg_t *msg);

static int msend(request_rec *r, const char *msg, int *len);
static int mrecv(request_rec *r, char *msg, int *len);

static apr_socket_t* mconnect(request_rec *r);
static void mclose(request_rec *r);


static int read_msg(request_rec *r, msg_t **msg)
{
    conn_rec *c = r->connection;
    apr_bucket_brigade *bb = apr_brigade_create(r->pool, c->bucket_alloc);
    char *dbuf = apr_palloc(r->pool, MAX_MSG_SIZE);
    int dbpos = 0;
    int seen_eos = 0;

    do {
        apr_status_t rv;
        apr_bucket *bucket;

        rv = ap_get_brigade(r->input_filters, bb, AP_MODE_READBYTES,
                            APR_BLOCK_READ, HUGE_STRING_LEN);

        if (rv != APR_SUCCESS) {
            ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r,
                          "reading request entity data");
            return HTTP_INTERNAL_SERVER_ERROR;
        }

        for (bucket = APR_BRIGADE_FIRST(bb);
             bucket != APR_BRIGADE_SENTINEL(bb);
             bucket = APR_BUCKET_NEXT(bucket))
        {
            const char *data;
            apr_size_t len;

            if (APR_BUCKET_IS_EOS(bucket)) {
                seen_eos = 1;
                break;
            }

            /* We can't do much with this. */
            if (APR_BUCKET_IS_FLUSH(bucket))
                continue;

            /* read */
            apr_bucket_read(bucket, &data, &len, APR_BLOCK_READ);

            if (dbpos < MAX_MSG_SIZE) {
                int cursize = (dbpos + len) > MAX_MSG_SIZE ?
                    (MAX_MSG_SIZE - dbpos) : len;

                memcpy(dbuf + dbpos, data, cursize);
                dbpos += cursize;
            }
        }

        apr_brigade_cleanup(bb);

    } while (!seen_eos);

    (*msg) = apr_pcalloc(r->pool, sizeof(msg_t));
    (*msg)->data = dbuf;
    (*msg)->data[dbpos] = '\0';
    (*msg)->size = dbpos;

    return OK;
}

static int write_msg(request_rec *r, msg_t *msg)
{
    ap_set_content_type(r, "application/octet-stream");
    ap_rputs(msg->data, r);

    return OK;
}

static int exchange(request_rec *r, msg_t *tmsg, msg_t **rmsg)
{
    char *data;
    char szbuf[4];
    int msgsz = 4;
    int rv;

    tmsg = decode(r, tmsg);
    
    if ((rv = msend(r, tmsg->data, &(tmsg->size))) != OK)
        return rv;

    if ((rv = mrecv(r, szbuf, &msgsz)) != OK)
        return rv;

    msgsz = (szbuf[3] << 24) | (szbuf[2] << 16) | (szbuf[1] << 8) | szbuf[0];
    msgsz -= 4;

    if (msgsz < 0 || msgsz > MAX_MSG_SIZE)
        return HTTP_BAD_REQUEST;

    data = apr_pcalloc(r->pool, msgsz);
    if ((rv = mrecv(r, data, &msgsz)) != OK)
        return rv;

    msgsz += 4;
    (*rmsg) = apr_pcalloc(r->pool, sizeof(msg_t));
    (*rmsg)->data = apr_pcalloc(r->pool, msgsz + 1);
    (*rmsg)->data[msgsz] = '\0';
    (*rmsg)->size = msgsz;

    memcpy((*rmsg)->data, szbuf, 4);
    memcpy((*rmsg)->data + 4, data, msgsz - 4);

    *rmsg = encode(r, *rmsg);

    return OK;
}

static int msend(request_rec *r, const char *msg, int *len)
{
    apr_status_t rv;
    apr_socket_t *s;
   
    if ((s = mconnect(r)) == NULL)
        return HTTP_INTERNAL_SERVER_ERROR;

    if ((rv = apr_socket_send(s, msg, len)) != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "send failed");
        mclose(r);

        return HTTP_INTERNAL_SERVER_ERROR;
    }

    return OK;
}

static int mrecv(request_rec *r, char *msg, int *len)
{
    apr_status_t rv;
    apr_socket_t *s;

    if ((s = mconnect(r)) == NULL)
        return HTTP_INTERNAL_SERVER_ERROR;

    if ((rv = apr_socket_recv(s, msg, len)) != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "recv failed");
        mclose(r);

        return HTTP_INTERNAL_SERVER_ERROR;
    }

    return OK;
}

static apr_socket_t *s = NULL;
static apr_sockaddr_t *addr = NULL;

static apr_socket_t* mconnect(request_rec *r)
{
    apr_status_t rv;
    process_rec *p = r->connection->base_server->process;

    if (s != NULL)
        return s;

    rv = apr_socket_create(&s, APR_INET, SOCK_STREAM, APR_PROTO_TCP, p->pool);
    if (rv != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "socket creation failed");
        mclose(r);

        return NULL;
    }

    rv = apr_socket_opt_set(s, APR_SO_KEEPALIVE, 1);
    if (rv != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "setting socket options");
        mclose(r);

        return NULL;
    }

    rv = apr_sockaddr_info_get(&addr, "localhost", APR_INET, 7777, 0, p->pool);
    if (rv != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "addr resolution failed");
        mclose(r);

        return NULL;
    }

    rv = apr_socket_connect(s, addr);
    if (rv != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "socket connect failed");
        mclose(r);

        return NULL;
    }

    return s;
}

// TODO: free apr_sockaddr_t *addr and apr_socket_t *s
// they use per process memory pool
static void mclose(request_rec *r)
{
    apr_status_t rv;
    if (s != NULL && (rv = apr_socket_close(s)) != APR_SUCCESS)
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "socket close failed");

    s = NULL;
}

#define d(ch) (((ch) < 97) ? ((ch) - 48) : ((ch) - 87))
#define e(ch) (((ch) < 10) ? ((ch) + 48) : ((ch) + 87))

static msg_t* decode(request_rec *r, msg_t *msg)
{
    msg_t *res = apr_pcalloc(r->pool, sizeof(msg_t));
    char *data = apr_pcalloc(r->pool, (msg->size / 2) + 1);

    int mi = 0, di = 0;
    for (; mi < (msg->size - 1); mi += 2, di++)
        data[di] = 16 * d(msg->data[mi]) + d(msg->data[mi + 1]);

    res->data = data;
    res->data[di] = '\0';
    res->size = di;

    ap_log_error(APLOG_MARK, APLOG_NOTICE, 0, r->server,
            "[D] m: %s, sz: %d, ressz: %d", msg == NULL ? NULL : msg->data,
            msg->size, di);

    return res;
}

static msg_t* encode(request_rec *r, msg_t *msg)
{
    msg_t *res = apr_pcalloc(r->pool, sizeof(msg_t));
    char *data = apr_pcalloc(r->pool, (msg->size * 2) + 1);

    int mi = 0, di = 0;
    for (; mi < msg->size; mi++, di += 2) {
        data[di] = e(msg->data[mi] >> 4);
        data[di + 1] = e(msg->data[mi] & 0x0F);
    }

    res->data = data;
    res->data[di] = '\0';
    res->size = di;

    ap_log_error(APLOG_MARK, APLOG_NOTICE, 0, r->server,
            "[E] m: %s, sz: %d, ressz: %d", res == NULL ? NULL : res->data,
            res->size, mi);

    return res;
}
