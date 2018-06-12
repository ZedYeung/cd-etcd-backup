#!/bin/bash
docker pull nginx

for i in $(seq 1 1000);
  do
    deployment=nginx${i}
    kubectl run ${deployment} --image=nginx:latest --replicas=1
    sleep 60
  done
