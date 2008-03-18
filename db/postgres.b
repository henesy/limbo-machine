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

    fd := sys->open(conn.dir + "/data", sys->ORDWR);
    spawn read(fd);

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

    sys->write(fd, msg.bytes, len msg.bytes);
    sys->print("Establishing a connection...\n");

    sys->sleep(1000);

    # send a simple query
    # msg = bin->new(nil);
    # msg.add_8(int "Q"[0]);
    # msg.add_32(0); # length
    # msg.add_string("select * from a;");
    # msg.set_32(len msg.bytes - 1, 1);
    # sys->write(fd, msg.bytes, len msg.bytes);
    # sys->print("Sending a query...\n");
    
    sys->sleep(2000);
}

read(fd: ref Sys->FD) 
{
    ok := 1;
    buf := array[1] of byte;
    while (ok > 0) {
         m := bin->read_msg(sys, fd);
         sys->print("mtype: %s, len: %d\n", char_as_str(m, 0), len m.bytes);
 
         pauthresp(m);
         perror(m);
         pparamstat(m);
    }
}

pparamstat(m: ref Msg)
{
    if (m.get_8(0) == 'S') {
        key := m.get_string(5);
        value := m.get_string(5 + len(key) + 1);
        sys->print("%s: %s\n", key, value);
    }
}

pauthresp(m: ref Msg)
{
    if (m.get_8(0) == 'R') {
        code := m.get_32(1);

        sys->print("CODE: %d\n", code);
        sys->print("VAL: %d\n", m.get_8(8));

        case (code) {
            8 =>
                value := m.get_32(5);
                sys->print("VAL: %d\n", value);
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
    }
}

perror(m: ref Msg)
{
    if (m.get_8(0) == 'E') {
        idx := 5;
        length := len m.bytes;
        tcode : int;
        while (idx < length && (tcode = m.get_8(idx)) != 0) {
#                 tcode := m.get_8(idx);
            str := m.get_string(++idx);
            sys->print("type: %s, value: %s\n", int_as_str(tcode), str);
            idx += 1 + len str;
        }
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
