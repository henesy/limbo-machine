base = `pwd`
dis = $base/dis
flags = -gw

init:
    mkdir $dis

clean:
    rm -rf $dis
    rm -f $base/*.dis $base/*.sbl

%.dis: %.b
    limbo $flags $stem.b && mv $stem.dis $stem.sbl $dis

start: clean init sample.dis server.dis
    $dis/server &

stop:
    kill Server
