implement Cgi;

include "sys.m";
include "draw.m";
include "bufio.m";
include "/appl/svc/httpd/httpd.m";
include "/appl/svc/httpd/cache.m";
include "/appl/svc/httpd/contents.m";

# Compile this program:
# ; limbo sample.b
# ... copy it to the httpd installation root:
# ; cp sample.dis /dis/svc/httpd
# ... run httpd:
# ; /dis/svc/httpd/httpd
# then open a browser on your native OS and go to:
# http://localhost/sample
init(g: ref Httpd->Private_info, req: Httpd->Request) {
    bufio := g.bufio;
    Iobuf: import bufio;

    g.bout.puts("<b>Sample Application</b>\n");
}
