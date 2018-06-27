#!/bin/bash
SLACK_APP="https://hooks.slack.com/services/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"
ENDPOINTS="http://10.50.216.13:4001,http://10.73.146.15:4001,http://10.92.215.12:4001"

cp ./.s3cfg ~/.s3cfg

# http:// is mandatory
etcdtool --peers ${ENDPOINTS} tree /

s3cmd ls s3://full-backup
secmd ls s3://diff-backup

IFS=","

for ENDPOINT in $ENDPOINTS;
do
  HEALTH=$(curl -L ${ENDPOINT}/health)
  curl -X POST -H 'Content-type: application/json' --data '{"text": ${ENDPOINT} ${HEALTH}}' ${SLACK_APP}
done
