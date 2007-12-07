implement Db;

include "sys.m";
    sys: Sys;
include "draw.m";

include "styx.m";
include "styxservers.m";
    nametree: Nametree;
    Tree: import nametree;
    styxservers: Styxservers;
    Styxserver, Navigator: import styxservers;

Qroot, Qctl, Qdata: con big iota;

Db: module {
    init: fn(ctxt: ref Draw->Context, argv: list of string);
};

init(nil: ref Draw->Context, nil: list of string)
{
    sys = load Sys Sys->PATH;

    styx := load Styx Styx->PATH;
    styx->init();

    styxservers = load Styxservers Styxservers->PATH;
    styxservers->init(styx);
    styxservers->traceset(1);

    nametree = load Nametree Nametree->PATH;
    nametree->init();

    sys->pctl(Sys->FORKNS, nil);

    service(sys->fildes(0));
}

service(fd : ref Sys->FD)
{
    sys->print("[c] start\n");

    (tree, treeop) := nametree->start();
    tree.create(Qroot, dir(".", 8r555|Sys->DMDIR, Qroot));
    tree.create(Qroot, dir("ctl", 8r666, Qctl));
    tree.create(Qroot, dir("data", 8r444, Qdata));
    (tchan, srv) := Styxserver.new(fd, Navigator.new(treeop), Qroot);

    while((gm := <-tchan) != nil) {
        # normally a pick on gm would act on
        # Tmsg.Read and Tmsg.Write at least
        srv.default(gm);
    }

    sys->print("[c] end\n");

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
