#!/bin/bash
apt-get install wget –y
wget -O - -q http://s3tools.org/repo/deb-all/stable/s3tools.key | apt-key add -
wget -O /etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list
apt-get update && apt-get install s3cmd
