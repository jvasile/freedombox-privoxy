INSTALL_DIR=/etc/privoxy

all: easyprivacy.action easylist.action https_everywhere.action

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


debian:
	@mkdir -p Debian/$(INSTALL_DIR)
	@echo Debian!

install: all
	mkdir -p $(INSTALL_DIR)
	cp config default.freedombox.filter match-all.freedombox.action default.freedombox.action https_everywhere.action easyprivacy.action easylist.action $(INSTALL_DIR)
	/etc/init.d/privoxy restart

clean:
	@rm -rf easyprivacy.action easyprivacy.list https_everywhere.action vendor/https-everywhere