// I T Name
// + - version
// - - auth
// + - flush
// + - attach
// + - walk
// + - open
// + - create
// + - read
// + - write
// + - clunk
// + - remove
// - - stat
// - - wstat
var NOFID = ~0;
var NOTAG = ~0;
var MAXWELEM = 16;

var Mode =
    {OREAD: 0, OWRITE: 1, ORDWR: 2, OEXEC: 3, OTRUNC: 0x10, ORCLOSE: 0x40};

// TODO: tag checks and asynch messaging
Styx = function(service, onerror) {
    this.conn = new Connection(service);
    this.onerror = onerror;
    this.tag = 0;
    this.msize = 4096;
    this.version = "9P2000";
}

Styx.prototype.version = function() {
    var tVersion = new Message([], MessageType.Tversion, NOTAG);
    tVersion.add32(this.msize);
    tVersion.addString(this.version);
    tVersion.adjustSize();

    var rVersion = this.conn.tx(tVersion);
    
    var e = getError(MessageType.Rversion, rVersion);
    if (e == null) {
        this.msize = rVersion.get32(7);
        this.version = rVersion.getString(11);
    }

    onerror(e);
}

Styx.prototype.flush = function(tag) {
    var tFlush = new Message([], MessageType.Tflush, this.tag++);
    tFlush.add32(tag);
    tFlush.adjustSize();

    var rFlush = this.conn.tx(tFlush);
    var e = getError(MessageType.Rflush, rFlush);
    if (e != null)
        this.onerror(e);
}

Styx.prototype.attach = function(fid, user, aname) {
    var tAttach = new Message([], MessageType.Tattach, this.tag++);
    tAttach.add32(fid);
    tAttach.add32(NOFID);
    tAttach.addString(user);
    tAttach.addString(aname);
    tAttach.adjustSize();

    var rAttach = this.conn.tx(tAttach);

    var e = getError(MessageType.Rattach, rAttach);
    if (e == null)
        return new Qid(7, rAttach);

    this.onerror(e);
    return null;
}

Styx.prototype.walk = function(fid, newfid, nwnames) {
    var tWalk = new Message([], MessageType.Twalk, this.tag++);
    tWalk.add32(fid);
    tWalk.add32(newfid);
    tWalk.add16(nwnames.length);
    for (var i = 0, len = nwnames.length; i < len; i++)
        tWalk.addString(nwname[i]);
    tWalk.adjustSize();

    var rWalk = this.conn.tx(tWalk);
    var e = getError(MessageType.Rwalk, rWalk);
    if (e == null) {
        var len = rWalk.get16(7);
        if (len != nwnames.length)
            this.onerror("walk error for path: " + nwnames);

        var res = [];
        while (--len >= 0)
            res.push(new Qid(9 + len * 13, rWalk));

        return res;
    }

    this.onerror(e);
    return [];
}

Styx.prototype.open = function(fid, mode) {
    var tOpen = new Message([], MessageType.Topen, this.tag++);
    tOpen.add32(fid);
    tOpen.add8(mode);
    tOpen.adjustSize();

    var rOpen = this.conn.tx(tOpen);
    var e = getError(MessageType.Ropen, rOpen);
    if (e == null) {
        // TODO: add iounit to Qid
        return new Qid(7, rOpen);
    }

    this.onerror(e);
    return null;
}

Styx.prototype.create = function(fid, name, perm, mode) {
    var tCreate = new Message([], MessageType.Tcreate, this.tag++);
    tCreate.add32(fid);
    tCreate.addString(name);
    tCreate.add32(perm);
    tCreate.add8(mode);
    tCreate.adjustSize();

    var rCreate = this.conn.tx(tCreate);
    var e = getError(MessageType.Rcreate, rCreate);
    if (e == null) {
        // TODO: add iounit to Qid
        return new Qid(7, rCreate);
    }

    this.onerror(e);
    return null;
}

Styx.prototype.read = function(fid, offset, cnt) {
    var tRead = new Message([], MessageType.Tread, this.tag++);
    tRead.add32(fid);
    tRead.add64(offset);
    tRead.add32(cnt);
    tRead.adjustSize();

    var rRead = this.conn.tx(tRead);
    var e = getError(MessageType.Rread, rAttach);
    if (e == null) {
        var len = rRead.get32(7);
        return rRead.bytes(9 + len);
    }

    this.onerror(e);
    return [];
}

Styx.prototype.write = function(fid, offset, data) {
    var tWrite = new Message([], MessageType.Twrite, this.tag++);
    tWrite.add32(fid);
    tWrite.add64(offset);
    tWrite.add32(data.length);
    for (var i = 0, len = data.length; i < len; i++)
        tWrite.add8(data[i]);

    var rWrite = this.conn.tx(tWrite);
    var e = getError(MessageType.Rwrite, rWrite);
    if (e == null)
        return rWrite.get32(7);

    this.onerror(e);
    return 0;
}

Styx.prototype.clunk = function(fid) {
    var tClunk = new Message([], MessageType.Tclunk, this.tag++);
    tClunk.add32(fid);
    tClunk.adjustSize();

    var rClunk = this.conn.tx(tClunk);
    var e = getError(MessageType.Rclunk, rClunk);
    if (e != null)
        this.onerror(e);
}

Styx.prototype.remove = function(fid) {
    var tRemove = new Message([], MessageType.Tremove, this.tag++);
    tRemove.add32(fid);
    tRemove.adjustSize();

    var rRemove = this.conn.tx(tRemove);
    var e = getError(MessageType.Rremove, rRemove);
    if (e != null)
        this.onerror(e);
}

function getError(type, msg) {
    var t = msg.get8(4);
    if (t == MessageType.Rerror)
        return "error: " + msg.getString(7);
    if (t != type)
        return "bad message type, exp: " + type + " was: " + t; 

    return null;
}
