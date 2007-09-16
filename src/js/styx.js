Styx = function(service, onerror) {
    this.conn = new Connection(service);
    this.onerror = onerror;
    this.tag = 0;
}

Styx.prototype.createMsg = function(type) {
    return add16(this.tag++, [0, 0, 0, 0, type]);
}

Styx.prototype.attach = function(fid, user, pass) {
    var tAttach = this.createMsg(MessageType.Tattach);
    add32(fid, tAttach);
    add32(~0, tAttach); // TODO: declare NOFID constant
    addString(user, tAttach);
    addString(pass, tAttach);
    adjustSize(tAttach);

    var rAttach = this.conn.tx(tAttach);

    var e = this.getError(MessageType.Rattach, rAttach);
    if (e == null)
        return getQid(rAttach);

    this.onerror(e);
    return null;
}

Styx.prototype.getError = function(type, msg) {
    var t = getType(msg);
    if (t == MessageType.Rerror)
        return "error: " + getString(msg, 6, msg.length);
    if (t != type)
        return "bad message type, exp: " + type + " was: " + t; 

    return null;
}

function add16(val, msg) {
    msg.push((val >> 8) & 0xFF);
    msg.push(val & 0xFF);

    return msg;
}

function add32(val, msg) {
    msg.push((val >> 24) & 0xFF);
    msg.push((val >> 16) & 0xFF);
    msg.push((val >> 8) & 0xFF);
    msg.push(val & 0xFF);

    return msg;
}

// TODO 
function addString(val, msg) {
    add16(val.length, msg);
    for (var i = 0, len = val.length; i < len; i++)
        msg.push(val.charCodeAt(i) & 0xFF);
}

function getString(data, from, to) {
    var res = [];
    for (var i = from; i < to; i++)
        res.push(String.fromCharCode(data[i] & 0xFF));

    return res.join("");
}

function adjustSize(msg) {
    var size = add32(msg.length, []);
    for (var i = 0; i < 4; i++)
        msg[i] = size[i];
}

function getType(msg) {
    return msg[5];
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
