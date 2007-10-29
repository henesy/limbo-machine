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

    (ok, conn) := sys->dial("tcp!localhost!5432", nil);
    if (ok < 0)
        raise "failed:dial";

    fd := sys->open(conn.dir + "/data", sys->ORDWR);
    spawn read(fd);

    # connect message
    msg := bin->new(nil);
    msg.add_32(0); # length of a message, change it
    msg.add_32(196608);
    msg.add_string("user");
    msg.add_string("Ostap"); # username, change it
    msg.add_string("xxx");
    msg.add_string("Ostap"); # dbname, change it
    msg.add_8(0);
    msg.set_32(len msg.bytes, 0); # adjust the message size field

    sys->write(fd, msg.bytes, len msg.bytes);
    sys->print("Establishing a connection...\n");

    sys->sleep(1000);

    # send a simple query
    msg = bin->new(nil);
    msg.add_8(int "Q"[0]);
    # msg.add_32( 20 );
    # msg.add_string("select * from a");
    msg.add_32(5);
    msg.add_string("");
    # msg.add_32(7);
    # msg.add_string("1");
    sys->write(fd, msg.bytes, len msg.bytes);
    sys->print("Sending a query...\n");
    
    sys->sleep(2000);
}

read(fd: ref Sys->FD) 
{
    ok := 1;
    while (ok > 0) {
        msg := bin->read_msg(sys, fd);
        sys->print("\nMessage type: %s\n", char_as_str(msg, 0));
    }
}
        
char_as_str(m: ref Msg, idx: int): string
{
    return string(array[1] of {* => byte m.get_8(idx)});
}
