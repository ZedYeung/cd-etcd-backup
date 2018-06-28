#!/bin/bash
SLACK_APP="https://hooks.slack.com/services/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"
RESTORE_HOST0=10.103.1.13
RESTORE_HOST1=10.103.1.14
RESTORE_HOST2=10.103.1.15
HOST0=10.103.1.16
HOST1=10.103.1.17
HOST2=10.103.1.18
PORT=2379

RESTORE_ENDPOINTS="http://${RESTORE_HOST0}:${PORT},http://${RESTORE_HOST1}:${PORT},http://${RESTORE_HOST2}:${PORT}"
ENDPOINTS="http://${HOST0}:${PORT},http://${HOST1}:${PORT},http://${HOST2}:${PORT}"

cp ./.s3cfg ~/.s3cfg

# http:// is mandatory
etcdctl --endpoints ${ENDPOINTS} cluster-health
etcdctl --endpoints ${RESTORE_ENDPOINTS} cluster-health

etcdtool --peers ${ENDPOINTS} tree /
etcdtool --peers ${RESTORE_ENDPOINTS} tree /

s3cmd ls s3://full-backup
s3cmd ls s3://diff-backup

IFS=","

for ENDPOINT in $ENDPOINTS;
do
  HEALTH=$(curl -L ${ENDPOINT}/health | jq -r '.health')
  if [ "$HEALTH" = false ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text": "'"${ENDPOINT}"' unhealthy"}' ${SLACK_APP}
  elif [ "$HEALTH" = true ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text": "'"${ENDPOINT}"' healthy"}' ${SLACK_APP}
  else
    curl -X POST -H 'Content-type: application/json' --data '{"text": "Could not detect"}' ${SLACK_APP}
  fi
done
