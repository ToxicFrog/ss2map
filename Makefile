# Very simple makefile.
# Put your mission and gamesys files in t1/, t2/, and ss2/, then run 'make all'
# and the maps will appear in 'maps/'.

default: ss2

all: ss2 t1 t2 zip

deploy:
	rsync -aPhv maps/ /mnt/net/funkyhorror.net/www/toxicfrog/maps/

zip:
	cd maps && rm -f t1-maps.zip t2-maps.zip ss2-maps.zip
	cd maps && zip -9 -r ss2-maps.zip ss2/
	cd maps && zip -9 -r t1-maps.zip t1/
	cd maps && zip -9 -r t2-maps.zip t2/

ss2:
	./mishtml --gamesys=ss2/shockscp.gam --proplist=proplist.ss2 --html-out=maps/ss2 ss2/{earth,station,eng,medsci,hydro,ops,rec,command,rick,many,shodan}*.mis

# T1: miss8.mis doesn't exist, miss18.mis is an easter egg(?) mission with no brushes
t1:
	./mishtml --gamesys=t1/dark.gam --proplist=proplist.t1 --html-out=maps/t1 t1/miss{1..7}.mis t1/miss{9..17}.mis

# T2: miss3.mis doesn't exist (cut partway through development)
t2:
	./mishtml --gamesys=t2/dark.gam --proplist=proplist.t2 --html-out=maps/t2 t2/miss{1,2}.mis t2/miss{4..16}.mis

.PHONY: ss2 t1 t2 zip deploy
