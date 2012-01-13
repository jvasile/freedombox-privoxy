#!/bin/bash
patchcount=90
prepend() {
    echo -e "$1"|cat - $2 > /tmp/out && mv /tmp/out $2
}
dir_setup() {
    ## Copy privoxy dir, set dir aliases and apply upstream dpatch patches
    PRIVDIR=`ls -d privoxy*| xargs | sed "s/ .*//"`
    FBOXDIR=freedombox-${PRIVDIR}

    echo PRIVDIR = ${PRIVDIR}
    echo FBOXDIR = ${FBOXDIR}
    rm -rf ${FBOXDIR}
    cp -r ${PRIVDIR} ${FBOXDIR}
    cp `ls -d privoxy*| xargs | sed -e"s/ .*//" -e "s/-/_/"`.orig.tar.gz freedombox-`ls -d privoxy*| xargs | sed -e"s/ .*//" -e "s/-/_/"`.orig.tar.gz
    cd ${FBOXDIR}
    dpatch apply-all
    cd ../..
    DEBDIR=`find Debian -maxdepth 1 -name "freedombox*" -type d`
    #`ls -d Debian/freedombox-privoxy*| xargs | sed "s/ .*//"`
    echo DEBDIR = ${DEBDIR}
}

add_patch() {
    echo Adding patch $1
    mkdir -p privoxy
    sed -i -e's/${patchcount}_$1.dpatch//' ${DEBDIR}/debian/patches/00list
    DEST=${DEBDIR}/debian/patches/${patchcount}_$1.dpatch
    diff -urNad ${DEBDIR}/$1 privoxy/$1 > ${DEST}
    prepend "#! /bin/sh /usr/share/dpatch/dpatch-run\n## ${patchcount}_$1.dpatch by James Vasile <james@jamesvasile.com>" ${DEST}
    echo ${patchcount}_$1.dpatch >> ${DEBDIR}/debian/patches/00list
    patchcount=`expr ${patchcount} + 1` 
}

update_control() {
    echo Updating control
    ## update control file
    cp privoxy/debian/control ${DEBDIR}/debian/control
}

update_changelog() {
    echo Updating changelog
    cp changelog changelog.debian
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
add_patch pcrs.c
add_patch pcrs.h
add_patch filters.c

update_changelog
update_control
update_rules
update_doc_base

cd Debian/${FBOXDIR}; 
dpatch apply-all
