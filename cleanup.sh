#!/bin/bash
crontab -r

etcdctl rm -r /

s3cmd rm s3://full-backup --recursive
s3cmd rm s3://diff-backup --recursive
