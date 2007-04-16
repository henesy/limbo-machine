httpdRoot=/dis/svc/httpd
flags=-g

prog:
    limbo $flags sample.b

install: prog
    cp sample.dis $httpdRoot
