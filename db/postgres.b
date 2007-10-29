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

    (ok, conn) := sys->dial("tcp!192.168.224.129!5432", nil);
    if (ok < 0)
        raise "failed:dial";

    fd := sys->open(conn.dir + "/data", sys->ORDWR);
    spawn read(sys, fd);

    # connect message
    msg := bin->new(nil);
    msg.add_32(42); #length of a message, change it
    msg.add_32(196608);
    msg.add_string("user");
    msg.add_string("postgres"); #username, change it
    msg.add_string("database");
    msg.add_string("template1"); #dbname, change it
    msg.add_8(0);

    sys->write(fd, msg.bytes, len msg.bytes);
    sys->print("Establishing a connection...\n");

    sys->sleep(1000);
}

read(sys: Sys, fd: ref Sys->FD) 
{
     # read resoosne
     ok := 1;
     while (ok > 0) {
       msg := bin->read_msg(sys, fd);
       sys->print("  Message type: %s\n", msg.get_char(0) );
     }
}
