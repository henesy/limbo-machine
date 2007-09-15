// var tAttach = ...; // binary message
// Connection c = new Connection('/myService');
// var rAttach = c.tx(tAttach);

Connection = function(service) {
    this.service = service;
}

Connection.prototype.tx = function(data) {
    var req = new XMLHttpRequest();
    netscape.security.PrivilegeManager.enablePrivilege(
            "UniversalBrowserRead");

    req.open("POST", this.service, false);
    req.overrideMimeType("text/plain; charset=x-user-defined");
    req.send(marshall(data));

    if (req.status > 299 || req.status < 200)
        return [];

    return unmarshall(req.responseText);
}

function marshall(data) {
    return data.join("");

//    var tmp = [];
//    for (var i = 0, len = data.length; i < len; i++)
//        tmp.push(String.fromCharCode(data[i] & 0xFF));
//
//    return tmp.join('');
}

function unmarshall(data) {
    var res = [];
    for (var i = 0, len = data.length; i < len; i++)
        res.push(data.charCodeAt(i) & 0xFF);

    return res;
}
