#!/bin/bash
ENDPOINTS="http://10.50.216.13:4001,http://10.73.146.15:4001,http://10.92.215.12:4001"

SLACK_APP="https://hooks.slack.com/services/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"

IFS=","

for ENDPOINT in $ENDPOINTS;
do
  if [ $(curl -L ${ENDPOINT}/health | jq '.health') = 'false' ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text": "${ENDPOINT} down"}' ${SLACK_APP}
  fi
done
