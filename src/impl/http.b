implement Machine;

include "sys.m";
    sys: Sys;

include "../module/machine.m";

init()
{
    sys = load Sys Sys->PATH;
}

service(fd : ref Sys->FD)
{
    sys->print("http connection\n");

    buf := array[4096] of byte;
    read := sys->read(fd, buf, len buf);

    sys->print("read %d bytes\n", read);

    msg := string buf[:read];

    sys->print("%s\n", msg);

    res := array of byte "HTTP/1.0 200 OK\nContent-Length: 9\n\nerror msg";
    
    sys->write(fd, res, len res);
}
