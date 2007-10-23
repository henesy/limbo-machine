implement Machine;

include "../module/machine.m";

include "cfg.m";
    cfg: Cfg;
include "sys.m";
    sys: Sys;

init()
{
    sys = load Sys Sys->PATH;
    cfg = load Cfg Cfg->PATH;
    cfg->init("dispatch.cfg");

    machines := build_map();
}

service(fd : ref Sys->FD)
{
    # do the redirects
}

MAP: con "map";

# create a navigation tree from the dispatch.cfg;
# load the corresponding modules;
build_map(): list of (string, Machine)
{
    machines : list of (string, Machine);

    records := cfg->lookup(MAP);
    for (; records != nil; records = tl records) {
        sys->print("1\n");
        (nil, record) := hd records;
        for (; record.tuples != nil; record.tuples = tl record.tuples) {
            sys->print("2\n");
            tuple := hd record.tuples;
            for (; tuple.attrs != nil; tuple.attrs = tl tuple.attrs) {
                sys->print("3\n");
                attr := hd tuple.attrs;
                if (attr.name == MAP) {
                    sys->print("MAP\n");
                    continue;
                }

                sys->print("4\n");
                m_name := attr.name;
                m_ctxt := attr.value;
                m_path := "";
                m_recs := cfg->lookup(m_name);
                if (len m_recs > 0) {
                    (m_path, nil) = hd m_recs;
                } else {
                    raise sys->sprint("config: missing '%s' machine", m_name);
                }

                sys->print("name: '%s'\n", m_name);
                sys->print("ctxt: '%s'\n", m_ctxt);
                sys->print("path: '%s'\n", m_path);

                m := load Machine m_path;
                m->init();

                machines = (m_ctxt, m) :: machines;
            }
        }
    }

    return machines;
}
