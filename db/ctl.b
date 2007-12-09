implement Service;

include "sys.m";
include "service.m";
include "bufio.m";
include "json.m";
    json: JSON;
    JValue: import json;

init(data: chan of ref JValue)
{
    json = load JSON JSON->PATH;
    bufio := load Bufio Bufio->PATH;
    json->init(bufio);
    spawn handler(data);
}

handler(data: chan of ref JValue)
{
    while ((tmsg := <- data) != nil) {
        if (!tmsg.isobject()) {
            data <- = error("input is not a json object");
            continue;
        }

        data <- = json->jvobject(("hello", json->jvstring("world")) :: nil);
    }
}

error(msg: string): ref JValue
{
    return json->jvobject(("error", json->jvstring(msg)) :: nil);
}
