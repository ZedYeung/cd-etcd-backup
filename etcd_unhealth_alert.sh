#!/bin/bash
HOSTS=(

)

EMAIL=YUE.YANG@CENTURYLINK.COM

for HOST in HOSTS;
do
  if [ $(curl -L ${HOST}/health | jq '.health') = 'false' ]; then
    mail -s "Alert: host ${HOST} down" ${EMAIL}
  fi
done
