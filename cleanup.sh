#!/bin/bash
RESTORE_HOST0=10.103.1.13
RESTORE_HOST1=10.103.1.14
RESTORE_HOST2=10.103.1.15
HOST0=10.103.1.16
HOST1=10.103.1.17
HOST2=10.103.1.18
PORT=2379

RESTORE_ENDPOINTS="http://${RESTORE_HOST0}:${PORT},http://${RESTORE_HOST1}:${PORT},http://${RESTORE_HOST2}:${PORT}"
ENDPOINTS="http://${HOST0}:${PORT},http://${HOST1}:${PORT},http://${HOST2}:${PORT}"

kill $(pgrep 'generate_random')
crontab -r

etcdctl --endpoints ${ENDPOINTS} rm -r /test
etcdctl --endpoints ${RESTORE_ENDPOINTS} rm -r /test

s3cmd rm s3://full-backup/*
s3cmd rm s3://diff-backup/*

rm -r /etcd_backup/full/
rm -r /etcd_backup/diff/

rm etcd-backup-full.log
rm etcd-backup-diff.log
rm etcd-unhealth-alert.log

sed -i '/^export/ d' /etc/profile
source /etc/profile
