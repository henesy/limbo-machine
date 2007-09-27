implement Machine;

include "sys.m";
    sys: Sys;
include "string.m";
    str: String;
# include "hash.m";
#     hash: Hash;

include "../module/machine.m";

Request: adt {
    request: string;
    # headers: ref HashTable; 
    headers: list of array of string;
    body: array of byte;
    str: fn(s: self Request): string;
};

Request.str(s: self Request): string
{
    res := "REQUEST: " + s.request + "\nHEADERS: ";
    for (; s.headers != nil; s.headers = tl s.headers)
        res += (hd s.headers)[0] + " : " + (hd s.headers)[1];
    res += "\nBODY: " + string(len s.body) + "(bytes)";

    return res;
}

init()
{
    sys = load Sys Sys->PATH;
    str = load String String->PATH;
    # hash = load Hash Hash->PATH;
}

service(fd : ref Sys->FD)
{
    sys->print("http connection\n");

    req := request(fd);
    sys->print("%s\n", req.str());
    
    error := array of byte
        "HTTP/1.0 200 OK\nContent-Length: 24\n\n0000000c6bffff0003616263";
    sys->write(fd, error, len error);
}

print(fd: ref Sys->FD)
{
    buf := array[4096] of byte;
    read := sys->read(fd, buf, len buf);

    sys->print("read %d bytes\n", read);

    msg := string buf[:read];

    sys->print("%s\n", msg);
}

# - What if headers exceed the buf size?
# - Read shd do more than one attempt.
request(fd: ref Sys->FD): Request
{
    buf := array[8192] of byte;
    read := sys->read(fd, buf, len buf);
    idx := indexOf(buf[0:read], "\r\n\r\n");
    if (idx < 0) {
        # empty body
    }

    (hlen, hlines) := sys->tokenize(string buf[0:idx], "\r\n");
    request := hd hlines;
    clen := 0;

    headers : list of array of string;
    for (hlines = tl hlines; hlines != nil; hlines = tl hlines) {
        line := array of byte hd hlines;
        i := indexOf(line, ":");
        if (i < 0)
            i = len line - 1;

        hdr = array[] of {string line[0:i], string line[i:]};

        sys->print("key: '%s', value: '%s'\n", hdr[0], hdr[1]);
        if (str->prefix("content-length", str->tolower(hdr[0])))
            (clen, nil) = str->toint(hdr[1], 10);

        headers = hdr :: headers;
    }

    body := array[clen] of byte;
    last := 0;
    for (i := (idx + 1); i < read; i++)
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
