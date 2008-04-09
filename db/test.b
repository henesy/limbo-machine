implement Test;

include "draw.m";
include "sys.m";
include "driver.m";
    driver: Driver;
    T: import driver;
    R: import driver;

Test: module {
    init: fn(ctxt: ref Draw->Context, argv: list of string);
};

init(nil: ref Draw->Context, nil: list of string)
{
    driver = load Driver "postgres.dis";
    driver->init();
    tc := driver->tchan();

    tc <- = ref T.Connect("tcp!localhost!5432", "ostap", "ostap");
}
