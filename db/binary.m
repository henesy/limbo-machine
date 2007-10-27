Binary: module {
    new: fn(src: array of byte): ref Msg;
    # This is a psql specific method
    read_msg: fn(sys: Sys, fd: ref Sys->FD): ref Msg;
    read_fully: fn(sys: Sys, fd: ref Sys->FD, buf: array of byte);
    
    Msg: adt {
        bytes: array of byte;

        add_8: fn(m: self ref Msg, val: int);
        add_16: fn(m: self ref Msg, val: int);
        add_32: fn(m: self ref Msg, val: int);
        add_string: fn(m: self ref Msg, val: string);

        set_8: fn(m: self ref Msg, val, idx: int);
        set_16: fn(m: self ref Msg, val, idx: int);
        set_32: fn(m: self ref Msg, val, idx: int);
        set_string: fn(m: self ref Msg, val: string, idx: int);

        get_8: fn(m: self ref Msg, idx: int): int;
        get_16: fn(m: self ref Msg, idx: int): int;
        get_32: fn(m: self ref Msg, idx: int): int;
        get_string: fn(m: self ref Msg, idx: int): string;
    };
};
