implement Machine;

include "sys.m";
    sys: Sys;
include "string.m";
    str: String;
# include "hash.m";
#     hash: Hash;

include "../module/machine.m";
    sample: Machine;

Request: adt {
    request: string;
    # headers: ref HashTable; 
    headers: list of array of string;
    body: array of byte;
    str: fn(s: self Request): string;
};

Request.str(s: self Request): string
{
    return "request: " + (string s.body);
}

pipe := array[2] of ref Sys->FD;

init()
{
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    # hash = load Hash Hash->PATH;

    sample = load Machine "sample.dis";
    sample->init();

    if (sys->pipe(pipe) != 0)
        raise "cannot create pipe";

    spawn sample->service(pipe[1]);
}

service(fd : ref Sys->FD)
{
    req := request(fd);
    sys->print("\n%s\n", req.str());

    data := unmarshall(req.body);
    sys->write(pipe[0], data, len data);

    buf := array[4096] of byte;
    read := sys->read(pipe[0], buf, len buf);

    resp := response(buf[:read]);
    sys->write(fd, resp, len resp);
}

response(body: array of byte): array of byte
{
    body = marshall(body);
    sys->print("response: %s\n", string body);
    return array of byte ("HTTP/1.0 200 OK\nContent-Length: "
         + string (len body) + "\n\n" + (string body));
}

# FIXME
# - What if headers exceed the buf size?
# - Read shd do more than one attempt.
# - Unsafe array indexing and too many constants.
request(fd: ref Sys->FD): Request
{
    buf := array[8192] of byte;
    read := sys->read(fd, buf, len buf);
    idx := indexOf(buf[0:read], "\r\n\r\n");
    if (idx < 0) {
        # empty body
    }

    (nil, hlines) := sys->tokenize(string buf[0:idx], "\r\n");
    request := hd hlines;
    clen := 0;

    headers : list of array of string;
    for (hlines = tl hlines; hlines != nil; hlines = tl hlines) {
        line := array of byte hd hlines;
        i := indexOf(line, ":");
        if (i < 0)
            i = len line - 1;

        hdr := array[] of {string line[0:i], string line[(i + 2):]};

        if (str->prefix("content-length", str->tolower(hdr[0])))
            clen = int hdr[1];

        headers = hdr :: headers;
    }

    body := array[clen] of byte;
    last := 0;
    for (i := (idx + 4); i < read; i++)
        body[last++] = buf[i];

    read = clen - (read - idx);
    if (read > 0)
        read = sys->pread(fd, body, read, big last); 

    return Request(request, headers, body);
}

indexOf(text: array of byte, str: string): int
{
    t := text;
    s := array of byte str;

    if (len s == 0)
        return 0;

    if (len s > len t)
        return -1;

    si := 0;
    idx := -1;
    for (ti := 0; ti < len t; ti++) {
        if (t[ti] != s[si]) {
            si = 0;
            continue;
        }

        if ((len t - ti) < (len s - si))
            break;

        if (si < (len s - 1)) {
            si++;
        } else {
            idx = ti - si;
            break;
        }
    }

    return idx;
}

marshall(buf: array of byte): array of byte
{
    res := array[(len buf) * 2] of byte;
    for (i := 0; i < len buf; i++) {
        res[2 * i] = enc(buf[i] >> 4);
        res[2 * i + 1] = enc(buf[i] & byte 16r0F);
    }

    return res;
}

enc(b: byte): byte
{
    x := byte 48;
    if (b >= byte 10)
        x = byte 87;

    return (b + x);
}

unmarshall(buf: array of byte): array of byte
{
    res := array[(len buf) / 2] of byte;
    idx := 0;
    for (i := 0; i < len buf; i += 2)
        res[idx++] = byte 16 * dec(buf[i]) + dec(buf[i + 1]);

    return res;
}

dec(b: byte): byte
{
    x := byte 48;
    if (b >= byte 97)
        x = byte 87;

    return (b - x);
}
