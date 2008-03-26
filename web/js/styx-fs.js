// I T Name
// + - mount(user, path): root
// + - unmount()
// + - create(path, perm, mode): resource
// + - open
// + - read
// + - write
// + - remove
// + - list
// + - close
StyxFS = function(service, onerror) {
    this.styx = new Styx(service, onerror);
    this.root = null;
    this.resources = {};
    this.lastFid = 2;
}

StyxFS.prototype.mount = function(user, aname) {
    this.styx.version();
    var qid = this.styx.attach(1, user, aname);
    this.root = new Resource(aname, 1, qid);

    return this.root;
}

StyxFS.prototype.unmount = function() {
    for (var key in this.resources)
        this.styx.clunk(this.resources[key].fid);

    if (this.root != null)
        this.styx.clunk(this.root.fid);

    this.resources = {};
    this.root = null;
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
        this.resources[res.key] = res;

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

StyxFS.prototype.read = function(res, offset, cnt) {
    return this.styx.read(res.fid, offset, cnt);
}

StyxFS.prototype.write = function(res, offset, data) {
    return this.styx.write(res.fid, offset, data);
}

StyxFS.prototype.remove = function(res) {
    return this.styx.remove(res.fid);
}

// FIXME: return all directory entries
StyxFS.prototype.list = function(res) {
    if (!res.opened) {
        res.qid = this.styx.open(res.fid, Mode.OREAD);
        res.opened = true;
    }

    var msg = new Message(this.styx.read(res.fid, 0, 4000));
    var dirs = [];
    for (var len = msg.length(), idx = 0; idx < len;) {
        var dir = new Dir(idx, msg);
        if (dir.sz == 0)
            break;

        dirs.push(dir);
        idx += (dir.sz + /* sz field itself */ 2);
    }

    return dirs;
}

StyxFS.prototype.close = function(res) {
    this.styx.clunk(res.fid);
    delete this.resources[res.fid];
}

function split(path) {
    return path.split("/+");
}

function walkTo(path) {
    var fid = this.lastFid++
    var qids = this.styx.walk(this.root.fid, fid, path);
    var res = new Resource(path, fid, qids[qids.length - 1]);
    this.resources[res.key] = res;

    return res;
}
