ETCD_VER=v3.3.8

GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=${GOOGLE_URL}

rm -f ~/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf ~/etcd-download-test && mkdir -p ~/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o ~/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf ~/etcd-${ETCD_VER}-linux-amd64.tar.gz -C ~/ --strip-components=1
rm -f ~/etcd-${ETCD_VER}-linux-amd64.tar.gz

~/etcd --version
ETCDCTL_API=3 ~/etcdctl version
