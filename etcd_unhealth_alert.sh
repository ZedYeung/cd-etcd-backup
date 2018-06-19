#!/bin/bash
HOSTS=(

)

SLACK_APP="https://hooks.slack.com/services/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"

EMAIL=YUE.YANG@CENTURYLINK.COM

for HOST in HOSTS;
do
  if [ $(curl -L ${HOST}/health | jq '.health') = 'false' ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text": "${HOST} down"}' ${SLACK_APP}
  fi
done
