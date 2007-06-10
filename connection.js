// var tAttach = ...; // binary message
// Connection c = new Connection('/myService');
// var rAttach = c.tx(tAttach);

Connection = function(service) {
    this.service = service;
}

Connection.prototype = {
    'tx': function(data) {
        var req = XMLHttpRequest();
// netscape.security.PrivilegeManager.enablePrivilege("UniversalBrowserRead");
        req.open('POST', this.service, false);
        req.overrideMimeType('text/plain; charset=x-user-defined');
        req.send(data);

        if (req.status > 299 || req.status < 200)
            return '';

        return req.responseText;
    }
}
