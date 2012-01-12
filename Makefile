INSTALL_DIR=/etc/privoxy
VERSION=`cat VERSION`
PACKAGE_NAME=freedombox-privoxy
DEBDIR=`ls -d Debian/privoxy*| xargs | sed "s/ .*//"`

all: easyprivacy.action easylist.action https_everywhere.action

easyprivacy.txt:
	@wget https://easylist-downloads.adblockplus.org/easyprivacy.txt

easylist.txt:
	@https://easylist-downloads.adblockplus.org/easylist.txt

easyprivacy.action: easyprivacy.txt
	@./abp_import.py easyprivacy.txt > easyprivacy.action

easylist.action: easylist.txt
	@./abp_import.py easylist.txt > easylist.action

vendor:
	@mkdir -p vendor

vendor/https-everywhere:
	@cd vendor; git clone git://git.torproject.org/https-everywhere.git https-everywhere

https_everywhere.action: vendor/https-everywhere
	@./https_everywhere_import.py > https_everywhere.action


deb: debian
debian:
	./make_deb.sh

install: all
	mkdir -p $(INSTALL_DIR)
	cp config default.freedombox.filter match-all.freedombox.action default.freedombox.action https_everywhere.action easyprivacy.action easylist.action $(INSTALL_DIR)
	/etc/init.d/privoxy restart

clean:
	@rm -rf easyprivacy.action easyprivacy.txt https_everywhere.action vendor/https-everywhere 1000_config.dpatch Debian/privoxy* Debian/freedombox-privoxy* easylist.action easylist.txt