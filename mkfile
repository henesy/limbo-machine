BASE = `pwd`
FLAGS = -gw -I$BASE/module
DEST = $BASE/dis

WEB = \
    web/limbo/server.dis \
    web/limbo/sample.dis \
    web/limbo/http.dis \
    web/limbo/dispatch.dis \

DB = \
    db/server.dis \
    db/postgres.dis \
    db/binary.dis \

ALL = ${DB:%=$DEST/%} ${WEB:%=$DEST/%}


init:
    mkdir -p $DEST/web/limbo
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

all:N: compile install
