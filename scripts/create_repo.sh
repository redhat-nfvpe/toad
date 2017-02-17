REPONAME=$1
PUBLIC_ADDRESS=$(hostname --ip-address)
REPOPATH="/var/ftp/pub/"
REPOFILE="${REPOPATH}/${REPONAME}/osp.repo"

mkdir -p $REPOPATH
rm $REPOFILE 2> /dev/null
touch $REPOFILE

echo "path is $REPOPATH"
echo "name is $REPONAME"
for DIR in `find ${REPOPATH}${REPO_NAME}/* -maxdepth 1 -mindepth 1 -type d`; do
    echo "directory"
    echo $DIR
    echo -e "[`basename $DIR`]" >> $REPOFILE
    echo -e "name=`basename $DIR`" >> $REPOFILE
    echo -e "baseurl=ftp://${PUBLIC_ADDRESS}/pub/${REPONAME}/`basename $DIR`/" >> $REPOFILE
    echo -e "enabled=1" >> $REPOFILE
    echo -e "gpgcheck=1" >> $REPOFILE
    echo -e "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release" >> $REPOFILE
    echo -e "\n" >> $REPOFILE
done;
