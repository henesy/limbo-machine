Qid = function(idx, msg) {
    this.type = msg.get8(idx);
    this.version = msg.get32(idx + 1);
    this.path = msg.get64(idx + 5);
};

Qid.prototype.getType = function() { return this.type; }
Qid.prototype.getVersion = function() { return this.version; }
Qid.prototype.getPath = function() { return this.path; }

var QidType = {QTFILE: 0, QTAUTH: 1, QTEXCL: 4, QTAPPEND: 8, QTDIR: 16}; 