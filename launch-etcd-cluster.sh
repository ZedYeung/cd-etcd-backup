#!/bin/bash
HOST0=10.103.1.16
HOST1=10.103.1.17
HOST2=10.103.1.18
INITIAL_CLUSTER_TOKEN=etcd-backup-cluster

HOST0=10.103.1.13
HOST1=10.103.1.14
HOST2=10.103.1.15
INITIAL_CLUSTER_TOKEN=etcd-restore-cluster

etcd --name backup0 --initial-advertise-peer-urls http://${HOST0}:2380 \
  --listen-peer-urls http://${HOST0}:2380 \
  --listen-client-urls http://${HOST0}:2379,http://127.0.0.1:2379 \
  --advertise-client-urls http://${HOST0}:2379 \
  --initial-cluster-token ${INITIAL_CLUSTER_TOKEN} \
  --initial-cluster backup0=http://${HOST0}:2380,backup1=http://${HOST1}:2380,backup2=http://${HOST2}:2380 \
  --initial-cluster-state new

etcd --name infra1 --initial-advertise-peer-urls http://${HOST1}:2380 \
  --listen-peer-urls http://${HOST1}:2380 \
  --listen-client-urls http://${HOST1}:2379,http://127.0.0.1:2379 \
  --advertise-client-urls http://${HOST1}:2379 \
  --initial-cluster-token ${INITIAL_CLUSTER_TOKEN} \
  --initial-cluster infra0=http://${HOST0}:2380,infra1=http://${HOST1}:2380,infra2=http://${HOST2}:2380 \
  --initial-cluster-state new

etcd --name infra2 --initial-advertise-peer-urls http://${HOST2}:2380 \
  --listen-peer-urls http://${HOST2}:2380 \
  --listen-client-urls http://${HOST2}:2379,http://127.0.0.1:2379 \
  --advertise-client-urls http://${HOST2}:2379 \
  --initial-cluster-token ${INITIAL_CLUSTER_TOKEN} \
  --initial-cluster infra0=http://${HOST0}:2380,infra1=http://${HOST1}:2380,infra2=http://${HOST2}:2380 \
  --initial-cluster-state new
