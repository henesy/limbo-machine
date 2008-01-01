implement Db;

include "draw.m";

include "sys.m";
    sys: Sys;
include "styx.m";
    styx: Styx;
    Rmsg: import styx;
    Tmsg: import styx;
include "styxservers.m";
    nametree: Nametree;
    Tree: import nametree;
    styxservers: Styxservers;
    Styxserver, Navigator: import styxservers;
include "bufio.m";
    bufio: Bufio;
    Iobuf: import bufio;
include "json.m";
    json: JSON;
    JValue: import json;
include "tables.m";
    tables: Tables;
    Table: import tables;
include "service.m";


Db: module {
    init: fn(ctxt: ref Draw->Context, argv: list of string);
};

svccnt: big;

Svc: adt {
    path: big;
    value: string;
    com: chan of ref JValue;
    # TODO: Sys->Dir and get rid of dir()
    mod: Service;

    new: fn(path: string): ref Svc;
};

Svc.new(path: string): ref Svc
{
    com := chan of ref JValue;
    mod := load Service path;
    mod->init(com);

    return ref Svc(svccnt++, "", com, mod);
}

services: ref Table[ref Svc];

init(nil: ref Draw->Context, nil: list of string)
{
    sys = load Sys Sys->PATH;

    styx = load Styx Styx->PATH;
    styx->init();

    styxservers = load Styxservers Styxservers->PATH;
    styxservers->init(styx);
    styxservers->traceset(1);

    nametree = load Nametree Nametree->PATH;
    nametree->init();

    bufio = load Bufio Bufio->PATH;

    json = load JSON JSON->PATH;
    json->init(bufio);

    tables = load Tables Tables->PATH;

    services = Table[ref Svc].new(8, nil);

    # TODO: root
    ctl := Svc.new("dis/db/ctl.dis");

    # THINK: do something with this cast (another module?)
    services.add(int ctl.path, ctl);

    sys->pctl(Sys->FORKNS, nil);

    service(sys->fildes(0));
}

service(fd : ref Sys->FD)
{
    Qctl, Qroot: con big iota;

    sys->print("[c] start\n");

    (tree, treeop) := nametree->start();
    tree.create(Qroot, dir(".", 8r555|Sys->DMDIR, Qroot));
    tree.create(Qroot, dir("ctl", 8r666, Qctl));
    (tchan, srv) := Styxserver.new(fd, Navigator.new(treeop), Qroot);

    while((gm := <-tchan) != nil) {
        pick m := gm {
        Read =>
            fid := srv.getfid(m.fid);
            svc := services.find(int fid.path);
            if (svc != nil) {
                srv.reply(styxservers->readstr(m, svc.value));
                continue;
            }
        Write =>
            fid := srv.getfid(m.fid);
            svc := services.find(int fid.path);
            if (svc != nil) {
                io := bufio->aopen(m.data);
                (jm, err) := json->readjson(io);
                if (jm == nil) {
                    srv.reply(ref Rmsg.Error(m.tag, err));
                    continue;
                }

                svc.com <- = jm;
                srv.reply(ref Rmsg.Write(m.tag, len m.data));
                svc.value = (<-svc.com).text();
                continue;
            }
        }

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
