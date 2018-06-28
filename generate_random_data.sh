#!/bin/bash
# NOW=$(date +'%Y%m%d-%H%M%S')
for i in $(seq 1 100);
do
  # deployment=nginx${i}
  # kubectl run ${deployment} --image=nginx:latest --replicas=1
  etcdctl --endpoints ${ENDPOINTS} set /test/case${i} $[${i} * 2 - 1]
  sleep ${GENERATE_INTERVAL}
done
