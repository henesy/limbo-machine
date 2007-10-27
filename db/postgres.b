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

init(nil: ref Draw->Context, argv: list of string)
{
    sys = load Sys Sys->PATH;
    bin = load Binary "binary.dis";

    spawn reader();

    sys->sleep(500);

    (ok, conn) := sys->dial("tcp!localhost!5432", nil);
    if (ok < 0)
        raise "failed:dial:is the ndb/cs running?";

    fd := sys->open(conn.dir + "/data", sys->ORDWR);

    msg := bin->new(nil);
    msg.add_8('W');
    msg.add_32(0); # reserve some space for msg size
    msg.add_string("Hello World");
    msg.add_32(65535);
    msg.set_32((len msg.bytes) - 1, 1); # adjust msg size (type is not incl)

    sys->write(fd, msg.bytes, len msg.bytes);
}

reader() {
    (ok, conn) := sys->announce("tcp!*!5432");
    if (ok < 0)
        raise "failed:announce:port in use?";
      
    (listen_ok, nc) := sys->listen(conn);
    if (listen_ok < 0)
        raise "failed:listen";

    fd := sys->open(nc.dir + "/data", sys->ORDWR);

    # buf := array[512] of byte;
    # read := sys->read(fd, buf, len buf);
    # sys->print("read: %d bytes\n", read);
    # sys->print("data: %s\n", string buf[:read]);

    msg := bin->read_msg(sys, fd);
    sys->print("length: %d\n", len msg.bytes);
    sys->print("byte: %d\n", msg.get_8(0));
    sys->print("int (size): %d\n", msg.get_32(1));
    sys->print("string: %s\n", msg.get_string(5));
    sys->print("int: %d\n", msg.get_32(17));
}
