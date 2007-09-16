implement Machine;

include "sys.m";
    sys: Sys;

include "../module/machine.m";

Request: adt {
    method: string;
    context: string;
    params: list of array of string;
    headers: list of array of string;
};

init()
{
    sys = load Sys Sys->PATH;
}

service(fd : ref Sys->FD)
{
    sys->print("http connection\n");

    # req := request(fd);
    print(fd);

    res := array of byte
            "HTTP/1.0 200 OK\nContent-Length: 18\n\n00000000006b616263";
    
    sys->write(fd, res, len res);
}

print(fd: ref Sys->FD)
{
    buf := array[4096] of byte;
    read := sys->read(fd, buf, len buf);

    sys->print("read %d bytes\n", read);

    msg := string buf[:read];

    sys->print("%s\n", msg);
}

request(fd: ref Sys->FD): Request
{
    buf := array[4096] of byte;
    read := sys->read(fd, buf, len buf);

    lines : list of string;
    line : list of byte;
    from := 0;
    for (i := 0; i < read; i++) {
        if (buf[i] == byte '\n') {
            lines = string buf[from : (i - 1)] :: lines;
            line : list of byte;
            from = (i + 1);
        }

        line = buf[i] :: line;
    }

    for (; lines != nil; lines = tl lines)
        sys->print("XXX: %s\n", hd lines);

    params : list of array of string;
    headers : list of array of string;

    return Request("", "", headers, params);
}
