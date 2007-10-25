implement Binary;

include "binary.m";
include "sys.m";

# FIXME: add_* are inefficient because of the small ensure_capacity footprint

new(src: array of byte): ref Msg
{
    if (src == nil) {
        return ref Msg(array[0] of byte, 0);
    } else {
        return ref Msg(src, len src);
    }
}

read_msg(sys: Sys, fd: ref Sys->FD): ref Msg
{
    sz_buf := array[4] of byte;
    read_fully(sys, fd, sz_buf);

    buf := array[new(sz_buf).get_32(0) - 4] of byte;
    read_fully(sys, fd, buf);

    return new(buf);
}

read_fully(sys: Sys, fd: ref Sys->FD, buf: array of byte)
{
    off := 0;
    sz := len buf;
    for (read := sys->pread(fd, buf, sz, big off); read < sz - off;) {
        off += read;
        read = sys->pread(fd, buf, sz - off, big off);
    }
}

Msg.add_8(m: self ref Msg, val: int)
{
    m.bytes = ensure_capacity(m.bytes, len m.bytes + 1);
    m.bytes[m.idx++] = byte(16rFF & val);
}

Msg.add_16(m: self ref Msg, val: int)
{
    m.add_8(val >> 8);
    m.add_8(val);
}

Msg.add_32(m: self ref Msg, val: int)
{
    m.add_16(val >> 16);
    m.add_16(val);
}

Msg.add_string(m: self ref Msg, val: string)
{
    str := array of byte val;
    for (i := 0; i < len str; i++)
        m.add_8(int str[i]);

    m.add_8(0);
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
