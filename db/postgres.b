implement Postgres;

include "binary.m";
    bin: Binary;
    Msg: import bin;

include "sys.m";
    sys: Sys;
include "draw.m";

Postgres: module {
    init: fn(ctxt: ref Draw->Context, argv: list of string);
};

# Please make sure that CS is running (; ndb/cs)
init(nil: ref Draw->Context, argv: list of string)
{
    sys = load Sys Sys->PATH;
    bin = load Binary "binary.dis";

    spawn reader();

    sys->sleep(1000);

    (ok, conn) := sys->dial("tcp!localhost!5432", nil);
    if (ok < 0)
        raise "failed:dial";

    fd := sys->open(conn.dir + "/data", sys->ORDWR);

    msg := bin->new(nil);
    msg.add_8('Q');
    msg.add_string("Hello World");

    sys->write(fd, msg.bytes, len msg.bytes);
}

reader() {
    (ok, conn) := sys->announce("tcp!*!5432");
    if (ok < 0)
        raise "failed:announce";
      
    (listen_ok, nc) := sys->listen(conn);
    if (listen_ok < 0)
        raise "failed:listen";

    fd := sys->open(nc.dir + "/data", sys->ORDWR);

    buf := array[512] of byte;
    read := sys->read(fd, buf, len buf);

    sys->print("read: %d bytes\n", read);
    sys->print("data: %s\n", string buf[:read]);
}
