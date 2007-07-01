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

    announce("tcp!*!7777");
}

announce(addr : string)
{
    (ok, conn) := sys->announce(addr);
    if (ok < 0)
        raise "cannot announce connection";

    for (;;)
        process(conn);
}

process(c : Sys->Connection)
{
    (ok, nc) := sys->listen(c);
    if (ok < 0)
        raise "listen failed";

    sys->print("incoming connection ...\n");

    machine = load Machine "sample.dis";
    machine->init();
    fd := sys->open(nc.dir + "/data", sys->ORDWR);

    spawn machine->service(fd);
}
