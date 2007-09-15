# start server: mk start
# stop server: mk stop
# clean: mk clean

# mount: mount -A tcp!localhost!7777 mnt
# unmount: unmount mnt

base = `pwd`
dis = $base/dis
src = $base/src/impl
flags = -gw

init:
    mkdir $dis

clean:
    rm -rf $dis
    rm -f $base/*.dis $base/*.sbl

%.dis: $src/%.b
    limbo $flags $src/$stem.b
    mv $stem.dis $stem.sbl $dis

build: clean init server.dis sample.dis http.dis
    ls $dis

start:
    cd $dis
    server &

stop:
    kill -g Server
