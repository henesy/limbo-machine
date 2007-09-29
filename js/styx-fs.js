// I T Name
// + - mount(user, path): root
// + - create
// + - open
// - - read
// - - write
// - - remove
// + - list
// - - close
StyxFS = function(service, onerror) {
    this.styx = new Styx(service, onerror);
    this.root = null;
    this.resources = [];
    this.lastFid = 2;
}

StyxFS.prototype.mount = function(user, aname) {
    this.styx.version();
    var qid = this.styx.attach(1, user, aname);
    this.root = new Resource(aname, 1, qid, Mode.OREAD);

    return this.root;
}

StyxFS.prototype.create = function(path, perm, mode) {
    var nws = split(path);
    var idx = nws.length - 1;
    var dir = walkTo(nws.slice(0, idx));
    var fid = this.lastFid++;
    var qid = null;
    if (dir != null)
        qid = this.styx.create(fid, nws[idx], perm, mode);
    
    var res = qid != null ? new Resource(nws, fid, qid, mode) : null;
    if (res != null)
        this.resources.push(res);

    return res;
}

StyxFS.prototype.open = function(path, mode) {
    var nws = split(path);
    var res = walkTo(nws);
    if (res != null) {
        var qid = this.styx.open(res.fid, mode);
        if (qid != null)
            res.mode = mode;
    }

    return res;
}

// resource operations
StyxFS.prototype.read = function(res, buf) {}
StyxFS.prototype.write = function(res, buf) {}
StyxFS.prototype.remove = function(res) {}

// FIXME: return all directory entries
StyxFS.prototype.list = function(res) {
    if (!res.opened)
        res.qid = this.styx.open(res.fid, Mode.ORDWR);
    var msg = new Message(this.styx.read(res.fid, 0, 4096));
    return [new Dir(0, msg)];
}

StyxFS.prototype.close = function(res) {}


function split(path) {
    return path.split("/+");
}

function walkTo(path) {
    var fid = this.lastFid++
    var qids = this.styx.walk(this.root.fid, fid, path);
    var res = new Resource(path, fid, qids[qids.length - 1], Mode.ORDWR);
    this.resources.push(res);

    return dir;
}
