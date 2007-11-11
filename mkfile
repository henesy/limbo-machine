# start server: mk start
# stop server: mk stop
# clean: mk clean
# build: mk build

# mount: mount -A tcp!localhost!7777 mnt
# unmount: unmount mnt

base = `pwd`
dis = $base/dis
web = $base/web
db = $base/db
flags = -gw

init:
    mkdir $dis

clean:
    rm -rf $dis
    rm -f $base/*.dis $base/*.sbl

%.dis: %.b 
    limbo $flags -o $stem.dis $stem.b 
    mv $stem.dis $stem.sbl $dis

build: clean init $web/server.dis $web/sample.dis \
       $web/http.dis $web/dispatch.dis \
       $db/postgres.dis $db/binary.dis
    cp $web/dispatch.cfg $dis

start-web:
    cd $dis
    server &

stop:
    kill -g Server
