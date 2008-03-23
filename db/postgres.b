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
init(nil: ref Draw->Context, nil: list of string)
{
    sys = load Sys Sys->PATH;
    bin = load Binary "binary.dis";

    (ok, conn) := sys->dial("tcp!localhost!5432", nil);
    if (ok < 0)
        raise "failed:dial";

    rdb := chan of ref Msg;
    wdb := chan of ref Msg;

    fd := sys->open(conn.dir + "/data", sys->ORDWR);

    spawn read(rdb, fd);
    spawn write(wdb, fd);

    s1 := chan of ref Msg;
    r1 := rdb;
    s2 := chan of ref Msg;
    r2 := s1;
    s3 := chan of ref Msg;
    r3 := s2;
    
    spawn pparamstat(s1, r1);
    spawn perror(s2, r2);
    spawn pauthresp(s3, r3);
    spawn punknown(s3);

    urchan := chan of string;
    uwchan := chan of string;

    # user interaction
    # connect message
    msg := bin->new(nil);
    msg.add_32(0); # length of a message, change it
    msg.add_16(3); # major protocol version
    msg.add_16(0); # minor protocol version
    msg.add_string("user");
    msg.add_string("ostap");
    msg.add_string("database");
    msg.add_string("ostap");
    msg.add_8(0);
    msg.set_32(35, 0); # adjust the message size field

    wdb <-= msg;

    # send a simple query
    # msg = bin->new(nil);
    # msg.add_8(int "Q"[0]);
    # msg.add_32(0); # length
    # msg.add_string("select * from a;");
    # msg.set_32(len msg.bytes - 1, 1);
    # sys->write(fd, msg.bytes, len msg.bytes);
    # sys->print("Sending a query...\n");
}

write(db: chan of ref Msg, fd: ref Sys->FD)
{
    for (;;) {
        m := <- db;
        sys->write(fd, m.bytes, len m.bytes);
    }
}

read(db: chan of ref Msg, fd: ref Sys->FD) 
{
    for (;;)
        db <-= bin->read_msg(sys, fd);
}

pparamstat(send: chan of ref Msg, recv: chan of ref Msg)
{
    for (;;) {
        m := <-recv;
        if (m.get_8(0) == 'S') {
            key := m.get_string(5);
            value := m.get_string(5 + len(key) + 1);
            sys->print("%s: %s\n", key, value);
        } else {
            send <-= m;
        }
    }
}

pauthresp(send: chan of ref Msg, recv: chan of ref Msg)
{
    for (;;) {
        m := <-recv;
        if (m.get_8(0) == 'R') {
            code := m.get_32(1);

            case (code) {
                8 =>
                    value := m.get_32(5);
                    case (value) {
                        0 =>
                            sys->print("connection successful\n");
                        2 =>
                            sys->print("kerberos required\n");
                        3 =>
                            sys->print("clear text password required\n");
                        6 =>
                            sys->print("SCM credentials required\n");
                        * =>
                            sys->print("unknown response value: %d\n", value);
                    }
                10 =>
                    value := m.get_32(5);
                    salt := m.bytes[9:];
                    sys->print("crypt() encryption password required\n");
                12 =>
                    value := m.get_32(5);
                    salt := m.bytes[9:];
                    sys->print("MD5-encrypted password required\n");
                * =>
                    sys->print("unknown code\n");
            }
        } else {
            send <-= m;
        }
    }
}

perror(send: chan of ref Msg, recv: chan of ref Msg)
{
    for (;;) {
        m := <-recv;
        if (m.get_8(0) == 'E') {
            idx := 5;
            length := len m.bytes;
            tcode : int;
            while (idx < length && (tcode = m.get_8(idx)) != 0) {
                str := m.get_string(++idx);
                sys->print("type: %s, value: %s\n", int_as_str(tcode), str);
                idx += 1 + len str;
            }
        } else {
            send <-= m;
        }
    }
}

punknown(recv: chan of ref Msg)
{
    for (;;) {
        m := <-recv;
        sys->print("unknown msg: %s, len: %d\n",
            char_as_str(m, 0), len m.bytes);
    }
}
        
char_as_str(m: ref Msg, idx: int): string
{
    return int_as_str(m.get_8(idx));
}

int_as_str(v: int): string
{
    return string(array[1] of {* => byte v});
}
