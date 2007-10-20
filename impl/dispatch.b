implement Machine;

include "cfg.m";
    cfg: Cfg;
include "sys.m"
    sys: Sys;

init()
{
    sys = load Sys Sys->PATH;
    cfg = load Cfg Cfg->PATH;
    cfg->init("dispatch.cfg");
}

service(fd : ref Sys->FD)
{
    dispatch := build_tree();
    # do the redirects
}

# create a navigation tree from the dispatch.cfg;
# load the corresponding modules;
build_tree(path: string): big
{
}
