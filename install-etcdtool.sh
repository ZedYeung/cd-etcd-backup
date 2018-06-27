#!/bin/bash
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
