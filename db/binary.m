Binary: module {
    new: fn(src: array of byte): ref Msg;
    read_msg: fn(sys: Sys, fd: ref Sys->FD): ref Msg;
    read_fully: fn(sys: Sys, fd: ref Sys->FD, buf: array of byte);
    
    Msg: adt {
        bytes: array of byte;

        # How to make it an implementation detail?
        idx: int;

        add_8: fn(m: self ref Msg, val: int);
        add_16: fn(m: self ref Msg, val: int);
        add_32: fn(m: self ref Msg, val: int);
        add_string: fn(m: self ref Msg, val: string);

        get_8: fn(m: self ref Msg, idx: int): int;
        get_16: fn(m: self ref Msg, idx: int): int;
        get_32: fn(m: self ref Msg, idx: int): int;
        get_string: fn(m: self ref Msg, idx: int): string;
    };
};
