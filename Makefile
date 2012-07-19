INSTALL_DIR=/etc/privoxy
VERSION=`cat VERSION`
PACKAGE_NAME=freedombox-privoxy
DEBDIR=`ls -d Debian/privoxy*| xargs | sed "s/ .*//"`

all: privoxy/easyprivacy.action privoxy/easylist.action privoxy/https_everywhere.action changelog

easyprivacy.txt:
	@wget https://easylist-downloads.adblockplus.org/easyprivacy.txt

easylist.txt:
	@wget https://easylist-downloads.adblockplus.org/easylist.txt

privoxy/easyprivacy.action: easyprivacy.txt abp_import.py
	@./abp_import.py easyprivacy.txt > privoxy/easyprivacy.action

privoxy/easylist.action: easylist.txt abp_import.py
	@./abp_import.py easylist.txt > privoxy/easylist.action

vendor:
	@mkdir -p vendor

vendor/https-everywhere:
	@mkdir -p vendor
	@rm -rf vendor/https_everywhere
	@cd vendor; git clone git://git.torproject.org/https-everywhere.git https-everywhere

privoxy/https_everywhere.action: vendor/https-everywhere https_everywhere_import.py
	@./https_everywhere_import.py > privoxy/https_everywhere.action

vendor/git2changelog/git2changelog.py:
	@mkdir -p vendor
	@rm -rf vendor/git2changelog
	@cd vendor; git clone git://github.com/jvasile/git2changelog.git git2changelog

# Note, this is the changelog for freedombox-privoxy, not for the debian package
changelog: .git/objects vendor/git2changelog/git2changelog.py
	@vendor/git2changelog/git2changelog.py freedombox-privoxy > changelog

deb: debian
debian: privoxy/easyprivacy.action privoxy/https_everywhere.action privoxy/easylist.action changelog
	./make_deb.sh
	cd `find Debian -maxdepth 1 -name "freedombox*" -type d`; debuild -us -uc #-kjames@jamesvasile.com

install: all
	mkdir -p $(INSTALL_DIR)
	cd privoxy; cp config default.filter match-all.action default.action https_everywhere.action easyprivacy.action easylist.action $(INSTALL_DIR)
	/etc/init.d/privoxy restart

clean:
	@rm -rf  vendor/https-everywhere 1000_config.dpatch Debian/privoxy* Debian/freedombox-privoxy* vendor/git2changelog
	@cd privoxy; rm -rf easyprivacy.action easyprivacy.txt https_everywhere.action easylist.action easylist.txt 