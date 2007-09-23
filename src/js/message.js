Message = function(bytes, type, tag) {
    this.mutable = (bytes.length == 0) ? true : false;
    this.bytes = bytes;
    if (tag != undefined) {
        this.add32(0);
        this.add8(type);
        this.add16(tag);
    }
}

Message.prototype.getBytes = function(from, to) {
    if (from == undefined)
        from = 0;
    if (to == undefined) 
        to = this.bytes.length;

    return this.bytes.slice(from, to);
}

Message.prototype.length = function() {
    return this.bytes.length;
}

Message.prototype.setString = function(idx, val) {
    this.assert(idx, 2 + val.length);
    this.add16(val.length);
    for (var i = 0, len = val.length; i < len; i++)
        this.add8(val.charCodeAt(i) & 0xFF);
}

Message.prototype.addString = function(val) {
    this.setString(this.bytes.length, val);
}

Message.prototype.getString = function(idx) {
    var res = [];
    var len = this.get16(idx);
    for (var i = idx + 2, len = this.get16(idx); i < len; i++)
        res.push(String.fromCharCode(get8(i)));

    return res.join("");
}

Message.prototype.set8 = function(idx, val) {
    this.assert(idx, 1);
    this.bytes[idx] = val & 0xFF;
}

Message.prototype.add8 = function(val) {
    this.set8(this.bytes.length, val);
}

Message.prototype.get8 = function(idx) {
    return this.bytes[idx] & 0xFF;
}

Message.prototype.set16 = function(idx, val) {
    this.assert(idx, 2);
    this.set8(idx++, (val >> 8) & 0xFF);
    this.set8(idx, val & 0xFF);
}

Message.prototype.add16 = function(val) {
    this.set16(this.bytes.length, val);
}

Message.prototype.get16 = function(idx) {
    return (this.get8(idx) << 8) | this.get8(idx + 1) ;
}

Message.prototype.set32 = function(idx, val) {
    this.assert(idx, 4);
    this.set16(idx, (val >> 16) & 0xFFFF);
    this.set16(idx + 2, val & 0xFFFF);
}

Message.prototype.add32 = function(val) {
    this.set32(this.bytes.length, val);
}

Message.prototype.get32 = function(idx) {
    return (this.get16(idx) << 16) | this.get16(idx + 2) ;
}

Message.prototype.set64 = function(idx, val) {
    this.assert(idx, 8);
    this.set32(idx, (val >> 32) & 0xFFFFFFFF);
    this.set32(idx + 4, val & 0xFFFFFFFFFF);
}

Message.prototype.add64 = function(val) {
    this.set64(this.bytes.length, val);
}

Message.prototype.get64 = function(idx) {
    return (this.get32(idx) << 32) | this.get32(idx + 4);
}

Message.prototype.assert = function(idx, len) {
    if (!this.mutable)
        this.onerror("object is immutable");

    var last = idx + len;
    if (last >= 4096)
        this.onerror("maximum message length: " + last);

    var dist = (this.bytes.length < last) ? (last - this.bytes.length) : 0;
    while (--dist > 0)
        this.bytes.push(0);
}

Message.prototype.adjustSize = function() {
    var size = this.set32(0, this.bytes.length);
}

var MessageType = {
    Tversion:   100,
    Rversion:   101,
    Tauth:      102,
    Rauth:      103,
    Tattach:    104,
    Rattach:    105,
    Rerror:     107,
    Tflush:     108,
    Rflush:     109,
    Twalk:      110,
    Rwalk:      111,
    Topen:      112,
    Ropen:      113,
    Tcreate:    114,
    Rcreate:    115,
    Tread:      116,
    Rread:      117,
    Twrite:     118,
    Rwrite:     119,
    Tclunk:     120,
    Rclunk:     121,
    Tremove:    122,
    Rremove:    123,
    Tstat:      124,
    Rstat:      125,
    Twstat:     126,
    Rwstat:     127,
    Tmax:       128
};
