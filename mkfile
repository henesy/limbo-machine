BASE = `pwd`
FLAGS = -gw -I$BASE/module
DEST = $BASE/dis

JS = \
    web/js/types.js \
    web/js/message.js \
    web/js/connection.js \
    web/js/styx-protocol.js \
    web/js/styx-fs.js \

WEB = \
    web/examples/http.dis \

DB = \
    db/server.dis \
    db/postgres.dis \
    db/binary.dis \
    db/ctl.dis \
    db/test.dis \

ALL = ${DB:%=$DEST/%} ${WEB:%=$DEST/%}

all:N: compile install

init:
    mkdir -p $DEST/web/examples
    mkdir -p $DEST/web/js
    mkdir -p $DEST/db

clean:
    rm -rf $DEST
    rm -f *.dis *.sbl */*.dis */*.sbl

%.dis: %.b 
    limbo $FLAGS -o $stem.dis $stem.b 

compile:N: clean init $WEB $DB

$DEST/%.dis: %.dis
    mv $prereq $target
    mv $stem.sbl $DEST/$stem.sbl

install:N: $ALL

# pkg: compile
#     puttar < $WEB $DB > pkg.tar
#     mkdir /db
#     tarfs pkg.tar /db

styx.js: init
    cat $JS > $DEST/web/js/styx.js
