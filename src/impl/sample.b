implement Machine;

include "sys.m";
    sys: Sys;
include "styx.m";
include "styxservers.m";
    nametree: Nametree;
    Tree: import nametree;
    styxservers: Styxservers;
    Styxserver, Navigator: import styxservers;

include "../module/machine.m";

Qroot, Qctl, Qdata: con big iota;

init()
{
    sys = load Sys Sys->PATH;
    styx := load Styx Styx->PATH;
    styx->init();
    styxservers = load Styxservers Styxservers->PATH;
    styxservers->init(styx);
    nametree = load Nametree Nametree->PATH;
    nametree->init();
    sys->pctl(Sys->FORKNS, nil);
}

service(fd : ref Sys->FD)
{
    sys->print("service\n");

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
