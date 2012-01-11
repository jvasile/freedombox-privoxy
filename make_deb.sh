#!/bin/sh

## Make working dir
mkdir -p Debian
cd Debian

## Install source package
apt-get source privoxy
echo You might need to "apt-get build-dep privoxy" as root

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

## Add config file as patch
sed -i -e's/1000_config.dpatch//' ${DEBDIR}/debian/patches/00list
echo "#! /bin/sh /usr/share/dpatch/dpatch-run" > 1000_config.dpatch
echo "## 1000_config.dpatch by James Vasile <james@jamesvasile.com>" >> 1000_config.dpatch
mkdir -p privoxy
cp config privoxy
diff -urNad ${DEBDIR}/config privoxy/config >> 1000_config.dpatch
mv 1000_config.dpatch ${DEBDIR}/debian/patches
echo 1000_config.dpatch >> ${DEBDIR}/debian/patches/00list
rm -rf privoxy

# Update changelog
echo -n "freedombox-" > changelog.debian
head -n 1 ${DEBDIR}/debian/changelog >> changelog.debian
echo "\\n  * Add FreedomBox config to package" >> changelog.debian
echo "\\n -- James Vasile <james@jamesvasile.com> " `date -R` \\n >> changelog.debian
cat ${DEBDIR}/debian/changelog >> changelog.debian
mv changelog.debian ${DEBDIR}/debian/changelog

## update control file
cp Debian/control ${DEBDIR}/debian/control

## Update rules file with freedombox- for dirs
cd ${DEBDIR}/debian
sed -i -e"s/^\(DEBDIR.*\)privoxy/\1freedombox-privoxy/" rules 
sed -i -e"s/\(cd.*DEBDIR.*\)privoxy/\1freedombox-privoxy/" rules

cd ..
debuild -us -uc
