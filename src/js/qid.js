Qid = function(idx, msg) {
    this.type = msg.get8(idx);
    this.version = msg.get32(idx + 1);
    this.path = msg.get64(idx + 5);
}

Qid.prototype.getType() { return this.type; }
Qid.prototype.getVersion() { return this.version; }
Qid.prototype.getPath() { return this.path; }
