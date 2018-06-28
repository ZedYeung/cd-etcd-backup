#!/bin/bash
# NOW=$(date +'%Y%m%d-%H%M%S')
GENERATE_INTERVAL=60

for i in $(seq 1 1000);
do
  # deployment=nginx${i}
  # kubectl run ${deployment} --image=nginx:latest --replicas=1
  etcdctl --endpoints ${ENDPOINTS} set /test/case${i} $[${i} * 2 - 1]
  sleep ${GENERATE_INTERVAL}
done
