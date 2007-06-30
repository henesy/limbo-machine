implement Server;

include "sys.m";
    sys: Sys;
include "draw.m";
include "styx.m";
include "styxservers.m";
    styxservers: Styxservers;
    Styxserver, Navigator: import styxservers;
    nametree: Nametree;
    Tree: import nametree;

# Based on example from the nametree(2).
# - compile this module: limbo -gw server.b
# - start this module in background: server &
# - mount it: mount -A tcp!localhost!7777 /n/server
Server: module
{
    init: fn(nil: ref Draw->Context, argv: list of string);
};

Qroot, Qctl, Qdata: con big iota;
init(nil: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    styx := load Styx Styx->PATH;
    styx->init();
    styxservers = load Styxservers Styxservers->PATH;
    styxservers->init(styx);
    nametree = load Nametree Nametree->PATH;
    nametree->init();
    sys->pctl(Sys->FORKNS, nil);

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

    spawn service(nc);
}

service(nc : Sys->Connection)
{
    (tree, treeop) := nametree->start();
    tree.create(Qroot, dir(".", 8r555|Sys->DMDIR, Qroot));
    tree.create(Qroot, dir("ctl", 8r666, Qctl));
    tree.create(Qroot, dir("data", 8r444, Qdata));

    fd := sys->open(nc.dir + "/data", sys->ORDWR);

    (tchan, srv) := Styxserver.new(fd, Navigator.new(treeop), Qroot);

    while((gm := <-tchan) != nil) {
        # normally a pick on gm would act on
        # Tmsg.Read and Tmsg.Write at least
        srv.default(gm);
    }

    tree.quit();
}

dir(name: string, perm: int, qid: big): Sys->Dir
{
    d := sys->zerodir;
    d.name = name;
    d.uid = "me";
    d.gid = "me";
    d.qid.path = qid;
    if (perm & Sys->DMDIR)
        d.qid.qtype = Sys->QTDIR;
    else
        d.qid.qtype = Sys->QTFILE;
    d.mode = perm;
    return d;
}
