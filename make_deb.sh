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
sed -i -e's/90_config.dpatch//' ${DEBDIR}/debian/patches/00list
echo "#! /bin/sh /usr/share/dpatch/dpatch-run" > 90_config.dpatch
#echo "## 90_config.dpatch by James Vasile <james@jamesvasile.com>" >> 90_config.dpatch
mkdir -p privoxy
cp config privoxy
diff -urNad ${DEBDIR}/config privoxy/config >> 90_config.dpatch
mv 90_config.dpatch ${DEBDIR}/debian/patches
echo 90_config.dpatch >> ${DEBDIR}/debian/patches/00list

## Add action/filter files as patches
cp default.action  match-all.action default.filter privoxy
echo "#! /bin/sh /usr/share/dpatch/dpatch-run" > 91_default.action.dpatch
diff -urNad ${DEBDIR}/default.action privoxy/default.action >> 91_default.action.dpatch
mv 91_default.action.dpatch ${DEBDIR}/debian/patches
echo 91_default.action.dpatch >> ${DEBDIR}/debian/patches/00list

echo "#! /bin/sh /usr/share/dpatch/dpatch-run" > 92_default.filter.dpatch
diff -urNad ${DEBDIR}/default.filter privoxy/default.filter >> 92_default.filter.dpatch
mv 92_default.filter.dpatch ${DEBDIR}/debian/patches
echo 92_default.filter.dpatch >> ${DEBDIR}/debian/patches/00list

echo "#! /bin/sh /usr/share/dpatch/dpatch-run" > 93_match-all.action.dpatch
diff -urNad ${DEBDIR}/match-all.action privoxy/match-all.action >> 93_match-all.action.dpatch
mv 93_match-all.action.dpatch ${DEBDIR}/debian/patches
echo 93_match-all.action.dpatch >> ${DEBDIR}/debian/patches/00list
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
sed -i -e"s/dh_installinit/dh_installinit --name=privoxy/" rules
mv init.d freedombox-privoxy.privoxy.init
#sed -i -e"s/\(cd.*DEBDIR.*\)privoxy/\1; ln -s freedombox-privoxy privoxy)\n\t(\1freedombox-privoxy/" rules

## update dirs in doc-base
sed -i -e"s/\/privoxy/\/freedombox-privoxy/" doc-base.*

cd ..
debuild -us -uc
