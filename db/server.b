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
include "service.m";
    ctl: Service;

ctlchan: chan of ref JValue;

Qroot, Qctl: con big iota;

Db: module {
    init: fn(ctxt: ref Draw->Context, argv: list of string);
};

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

    ctlchan = chan of ref JValue;

    ctl = load Service "dis/db/ctl.dis";
    ctl->init(ctlchan);

    sys->pctl(Sys->FORKNS, nil);

    service(sys->fildes(0));
}

service(fd : ref Sys->FD)
{
    sys->print("[c] start\n");

    (tree, treeop) := nametree->start();
    tree.create(Qroot, dir(".", 8r555|Sys->DMDIR, Qroot));
    tree.create(Qroot, dir("ctl", 8r666, Qctl));
    (tchan, srv) := Styxserver.new(fd, Navigator.new(treeop), Qroot);

    ctldata := "";
    while((gm := <-tchan) != nil) {
        pick m := gm {
        Read =>
            fid := srv.getfid(m.fid);
            if (fid.path == Qctl) {
                srv.reply(styxservers->readstr(m, ctldata));
                continue;
            }
        Write =>
            fid := srv.getfid(m.fid);
            if (fid.path == Qctl) {
                io := bufio->aopen(m.data);
                (jm, err) := json->readjson(io);
                if (jm == nil) {
                    srv.reply(ref Rmsg.Error(m.tag, err));
                    continue;
                }

                ctlchan <- = jm;
                srv.reply(ref Rmsg.Write(m.tag, len m.data));
                ctldata = (<-ctlchan).text();
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
