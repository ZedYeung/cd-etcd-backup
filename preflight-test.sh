#!/bin/bash
SLACK_APP="https://hooks.slack.com/services/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"
ENDPOINTS="http://10.50.216.13:4001,http://10.73.146.15:4001,http://10.92.215.12:4001"

cp ./.full-s3cfg ~/.full-s3cfg
cp ./.diff-s3cfg ~/.diff-s3cfg
FULL_BACKUP_S3CFG=~/.full-s3cfg
DIFF_BACKUP_S3CFG=~/.diff-s3cfg

# http:// is mandatory
etcdtool --peers ${ENDPOINTS} tree /

s3cmd -c ${FULL_BACKUP_S3CFG} ls s3://full-backup
secmd -c ${DIFF_BACKUP_S3CFG} ls s3://diff-backup

IFS=","

for ENDPOINT in $ENDPOINTS;
do
  HEALTH=$(curl -L ${ENDPOINT}/health)
  curl -X POST -H 'Content-type: application/json' --data '{"text": ${ENDPOINT} ${HEALTH}}' ${SLACK_APP}
done
