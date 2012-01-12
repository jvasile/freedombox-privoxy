#!/bin/bash

patchcount=90
dir_setup() {
    ## Copy privoxy dir, set dir aliases and apply upstream dpatch patches
    PRIVDIR=`ls -d privoxy*| xargs | sed "s/ .*//"`
    FBOXDIR=freedombox-${PRIVDIR}
    rm -rf ${FBOXDIR}
    cp -r ${PRIVDIR} ${FBOXDIR}
    cp `ls -d privoxy*| xargs | sed -e"s/ .*//" -e "s/-/_/"`.orig.tar.gz freedombox-`ls -d privoxy*| xargs | sed -e"s/ .*//" -e "s/-/_/"`.orig.tar.gz
    cd ${FBOXDIR}
    dpatch apply-all
    cd ../..
    DEBDIR=`ls -d Debian/freedombox-privoxy*| xargs | sed "s/ .*//"`
}

add_patch() {
    echo Adding patch $1
    mkdir -p privoxy
    sed -i -e's/${patchcount}_$1.dpatch//' ${DEBDIR}/debian/patches/00list
    echo "#! /bin/sh /usr/share/dpatch/dpatch-run" > ${patchcount}_$1.dpatch
    echo "## ${patchcount}_$1.dpatch by James Vasile <james@jamesvasile.com>" >> ${patchcount}_$1.dpatch
    cp $1 privoxy
    diff -urNad ${DEBDIR}/$1 privoxy/$1 >> ${patchcount}_$1.dpatch
    mv ${patchcount}_$1.dpatch ${DEBDIR}/debian/patches
    echo ${patchcount}_$1.dpatch >> ${DEBDIR}/debian/patches/00list
    patchcount=`expr ${patchcount} + 1` 
}

update_control() {
    echo Updating control
    ## update control file
    cp Debian/control ${DEBDIR}/debian/control
}

update_changelog() {
    echo Updating changelog
    # Update changelog
    echo -n "freedombox-" > changelog.debian
    head -n 1 ${DEBDIR}/debian/changelog >> changelog.debian
    echo -e "\n  * Add FreedomBox config to package" >> changelog.debian
    echo -e "\n -- James Vasile <james@jamesvasile.com> " `date -R` "\n" >> changelog.debian
    cat ${DEBDIR}/debian/changelog >> changelog.debian
    mv changelog.debian ${DEBDIR}/debian/changelog
}

update_rules() {
    echo Updating rules
    ## Update rules file
    pushd ${DEBDIR}/debian
    sed -i -e"s/^\(DEBDIR.*\)privoxy/\1freedombox-privoxy/" rules 
    sed -i -e"s/\(cd.*DEBDIR.*\)privoxy/\1freedombox-privoxy/" rules
    sed -i -e"s/dh_installinit/dh_installinit --name=privoxy/" rules
    mv init.d freedombox-privoxy.privoxy.init
    sed -i '/install -m.*trust/i \\tinstall -m 0644 https_everywhere.action $(DEBDIR)/etc/privoxy/https_everywhere.action' rules
    sed -i '/install -m.*trust/i \\tinstall -m 0644 easyprivacy.action $(DEBDIR)/etc/privoxy/easyprivacy.action' rules
    sed -i '/install -m.*trust/i \\tinstall -m 0644 easylist.action $(DEBDIR)/etc/privoxy/easylist.action' rules
    popd
    #sed -i -e"s/\(cd.*DEBDIR.*\)privoxy/\1; ln -s freedombox-privoxy privoxy)\n\t(\1freedombox-privoxy/" rules
}

update_doc_base() {
    echo Updating doc_base
    ## update dirs in doc-base
    pushd ${DEBDIR}/debian
    sed -i -e"s/\/privoxy/\/freedombox-privoxy/" doc-base.*
    popd
}

## Make working dir
mkdir -p Debian
cd Debian

## Install source package
apt-get source privoxy
echo You might need to \"apt-get build-dep privoxy\" as root

dir_setup

add_patch config
add_patch match-all.action
add_patch default.action
add_patch default.filter
add_patch easyprivacy.action
add_patch easylist.action
add_patch https_everywhere.action
rm -rf privoxy

update_changelog
update_control
update_rules
update_doc_base

cd ${DEBDIR}
debuild -us -uc
