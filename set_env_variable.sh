#!/bin/bash
mkdir -p /etcd_backup/full/
mkdir -p /etcd_backup/diff/

cat>>/etc/profile<<EOF
export SLACK_APP="https://hooks.slack.com/services/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"
export HOST0=10.103.1.16
export HOST1=10.103.1.17
export HOST2=10.103.1.18
export PORT=2379
export ENDPOINTS="http://${HOST0}:${PORT},http://${HOST1}:${PORT},http://${HOST2}:${PORT}"
export FULL_BACKUP_OBJECT_STORAGE_BUCKET=s3://full-backup
export DIFF_BACKUP_OBJECT_STORAGE_BUCKET=s3://diff-backup
export FULL_BACKUP_DIR=/etcd_backup/full/
export DIFF_BACKUP_DIR=/etcd_backup/diff/
export PRIVATE_KEY_PEM=~/.ssh/backup_private_key.pem
export PUBLIC_KEY_PEM=~/.ssh/backup_public_key.pem
export BACKUP_ENDPOINT=/
EOF
