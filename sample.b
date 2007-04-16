implement Cgi;

include "sys.m";
include "draw.m";
include "bufio.m";
include "/appl/svc/httpd/httpd.m";
include "/appl/svc/httpd/cache.m";
include "/appl/svc/httpd/contents.m";

init(g: ref Httpd->Private_info, req: Httpd->Request) {
    bufio := g.bufio;
    Iobuf: import bufio;

    g.bout.puts("<b>Sample Application</b>\n");
}
