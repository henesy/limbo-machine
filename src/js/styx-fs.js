StyxFS = function(service, onerror) {
    this.styx = new Styx(service, onerror);
    this.root = null;
    this.resources = [];
    this.lastFid = 2;
}

StyxFS.prototype.mount = function(user, aname) {
    this.styx.version();
    var qid = this.styx.attach(1, user, aname);
    this.resources.push(new Resource("/", 1, qid, Mode.OREAD));
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
    var idx = nws.length - 1;
    var res = walkTo(nws);
    if (res != null) {
        var qid = this.styx.open(res.getFid(), mode);
        if (qid != null)
            res.mode = mode;
    }

    return res;
}

// resource operations
StyxFS.prototype.read = function(res, buf) {}
StyxFS.prototype.write = function(res, buf) {}
StyxFS.prototype.remove = function(res) {}
StyxFS.prototype.list = function(res) {}
StyxFS.prototype.close = function(res) {}

Resource = function(path, fid, qid, mode) {
    this.path = path;
    this.fid = fid;
    this.qid = qid;
    this.mode = mode;
}
Resource.prototype.getPath() { return this.path; }
Resource.prototype.getFid() { return this.fid; }
Resource.prototype.getQid() { return this.qid; }
Resource.prototype.getMode() { return this.mode; }

function split(path) {
    return path.split("/+");
}

function walkTo(path) {
    var fid = this.lastFid++
    var qids = this.styx.walk(this.root.getFid(), fid, path);
    var res = new Resource(path, fid, qids[qids.length - 1], Mode.ORDWR);
    this.resources.push(res);

    return dir;
}
