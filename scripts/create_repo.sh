ADDRESS=$1
REPONAME=$2
HOSTNAME=$(hostname -f)
REPOPATH="/var/ftp/pub/"
REPOFILE="${REPOPATH}/${REPONAME}/osp.repo"

mkdir -p $REPOPATH
cp -R "${ADDRESS}/${REPONAME}/" ${REPOPATH}
rm $REPOFILE 2> /dev/null
touch $REPOFILE

for DIR in `find ${REPOPATH}${REPO_NAME}/* -maxdepth 1 -mindepth 1 -type d`; do
    echo -e "[`basename $DIR`]" >> $REPOFILE
    echo -e "name=`basename $DIR`" >> $REPOFILE
    echo -e "baseurl=ftp://$HOSTNAME/pub/${REPONAME}/`basename $DIR`/" >> $REPOFILE
    echo -e "enabled=1" >> $REPOFILE
    echo -e "gpgcheck=1" >> $REPOFILE
    echo -e "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release" >> $REPOFILE
    echo -e "\n" >> $REPOFILE
done;

