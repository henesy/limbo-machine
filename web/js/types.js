var NOFID = ~0;
var NOTAG = ~0;
var MAXWELEM = 16;

Resource = function(path, fid, qid, mode, opened) {
    this.key = "_" + fid;
    this.path = path;
    this.fid = fid;
    this.qid = qid;
    this.mode = (mode == undefined) ? Mode.OREAD : mode;
    this.opened = (opened == undefined) ? false : opened;
}

Dir = function(idx, msg) {
    this.sz = msg.get16(idx);
    this.type = msg.get16(idx += 2);
    this.dev = msg.get32(idx += 2);
    this.qid = new Qid(idx += 4, msg);
    this.mode = msg.get32(idx += 13);
    this.atime = msg.get32(idx += 4);
    this.mtime = msg.get32(idx += 4);
    this.length = msg.get64(idx += 4);
    this.name = msg.getString(idx += 8);
    this.uid = msg.getString(idx += (this.name.length + 2));
    this.gid = msg.getString(idx += (this.uid.length + 2));
    this.muid = msg.getString(idx += (this.gid.length + 2));
}

Qid = function(idx, msg) {
    this.type = msg.get8(idx);
    this.version = msg.get32(idx + 1);
    this.path = msg.get64(idx + 5);
}

var QidType = {
    QTDIR: 0x80,
    QTAPPEND: 0x40,
    QTEXCL: 0x20,
    QTAUTH: 0x08,
    QTTMP: 0x04,
    QTFILE: 0,
}; 

var Mode = {
    OREAD: 0,
    OWRITE: 1,
    ORDWR: 2,
    OTRUNC: 0x10,
    ORCLOSE: 0x40,
    OEXCL: 0x1000
};
