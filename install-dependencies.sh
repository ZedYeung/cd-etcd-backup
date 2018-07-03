#!/bin/bash
echo "install jq"
apt install -y jq

echo "install etcd"
ETCD_VER=v3.3.8

GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=${GOOGLE_URL}

rm -f ~/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf ~/etcd-download-test && mkdir -p ~/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o ~/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf ~/etcd-${ETCD_VER}-linux-amd64.tar.gz -C ~/ --strip-components=1
rm -f ~/etcd-${ETCD_VER}-linux-amd64.tar.gz

cp ~/etcd /usr/bin/etcd
cp ~/etcdctl /usr/bin/etcdctl

etcd --version
ETCDCTL_API=3 etcdctl version

echo "install go..."
VERSION=1.10.3
OS=linux
ARCH=amd64

apt-get update
apt-get -y upgrade

curl -O https://storage.googleapis.com/golang/go$VERSION.$OS-$ARCH.tar.gz
tar -C /usr/local -xvf go$VERSION.$OS-$ARCH.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile

go version

echo "install gb..."
go get github.com/constabulary/gb/...

echo "install etcdtool"
git clone https://github.com/mickep76/etcdtool.git
cd etcdtool
make
cp ./build/etcdtool /usr/bin/etcdtool
etcdtool --version

echo "install s3cmd"
apt-get install wget –y
wget -O - -q http://s3tools.org/repo/deb-all/stable/s3tools.key | apt-key add -
wget -O /etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list
apt-get update && apt-get install s3cmd
