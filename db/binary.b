implement Binary;

include "binary.m";
include "sys.m";

new(src: array of byte): ref Msg
{
    if (src == nil) {
        return ref Msg(array[0] of byte);
    } else {
        return ref Msg(src);
    }
}

# TODO: handle sys->readn() non-positive response codes (errors)
read_msg(sys: Sys, fd: ref Sys->FD): ref Msg
{
    sz_buf := array[5] of byte;
    sys->readn(fd, sz_buf, len sz_buf);

    sz := new(sz_buf[1:]).get_32(0);

    buf := array[sz - 4] of byte;
    sys->readn(fd, buf, len buf);

    res := array[sz + 1] of byte;

    i := 0;
    for (; i < len sz_buf; i++)
        res[i] = sz_buf[i];

    for (; i < len res; i++)
        res[i] = buf[i - len(sz_buf)];

    return new(res);
}

Msg.set_8(m: self ref Msg, val, idx: int)
{
    if (idx >= len m.bytes)
        m.bytes = ensure_capacity(m.bytes, idx + 1);

    m.bytes[idx] = byte(16rFF & val);
}

Msg.set_16(m: self ref Msg, val, idx: int)
{
    if (idx + 2 >= len m.bytes)
        m.bytes = ensure_capacity(m.bytes, idx + 2);

    m.set_8(val >> 8, idx);
    m.set_8(val, idx + 1);
}

Msg.set_32(m: self ref Msg, val, idx: int)
{
    if (idx + 4 >= len m.bytes)
        m.bytes = ensure_capacity(m.bytes, idx + 4);

    m.set_16(val >> 16, idx);
    m.set_16(val, idx + 2);
}

Msg.set_string(m: self ref Msg, val: string, idx: int)
{
    if (idx + len val + 1 >= len m.bytes)
        m.bytes = ensure_capacity(m.bytes, idx + len val + 1);

    str := array of byte val;
    for (i := 0; i < len str; i++)
        m.set_8(int str[i], idx++);

    m.set_8(0, idx);
}

Msg.add_8(m: self ref Msg, val: int)
{
    m.set_8(val, len m.bytes);
}

Msg.add_16(m: self ref Msg, val: int)
{
    m.set_16(val, len m.bytes);
}

Msg.add_32(m: self ref Msg, val: int)
{
    m.set_32(val, len m.bytes);
}

Msg.add_string(m: self ref Msg, val: string)
{
    m.set_string(val, len m.bytes);
}

Msg.get_8(m: self ref Msg, idx: int): int
{
    return int m.bytes[idx];
}

Msg.get_16(m: self ref Msg, idx: int): int
{
    return (m.get_8(idx) << 8) | m.get_8(idx + 1);
}

Msg.get_32(m: self ref Msg, idx: int): int
{
    return (m.get_16(idx) << 16) | m.get_16(idx + 2);
}

Msg.get_string(m: self ref Msg, idx: int): string
{
    str : list of byte;
    for (i := idx; i < len m.bytes && m.bytes[i] != byte 0; i++)
        str = m.bytes[i] :: str;

    return string to_array(str);
}

to_array(l: list of byte): array of byte
{
    res := array[len l] of byte;
    for (idx := (len l) - 1; l != nil; l = tl l)
        res[idx--] = hd l;

    return res;
}

ensure_capacity(bytes: array of byte, capacity: int): array of byte
{
    res : array of byte;
    if (capacity > len bytes) {
        res = array[capacity] of byte;
        for (i := 0; i < len bytes; i++)
            res[i] = bytes[i];
    } else {
        res = bytes;
    }

    return res;
}
