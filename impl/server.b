implement Server;

include "draw.m";
include "sys.m";
    sys: Sys;

include "../module/machine.m";
    machine: Machine;

Server: module
{
    init: fn(ctxt: ref Draw->Context, argv: list of string);
};

init(nil: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    sys->pctl(Sys->NEWPGRP, nil);

    (ok, conn) := sys->announce("tcp!*!7777");
    if (ok < 0)
        raise "cannot announce connection";

    machine = load Machine "http.dis";
    machine->init();

    for (;;) {
        (ok, nc) := sys->listen(conn);
        if (ok < 0)
            raise "listen failed";

        fd := sys->open(nc.dir + "/data", sys->ORDWR);

        spawn machine->service(fd);
    }
}
