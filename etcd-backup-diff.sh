#!/bin/bash
HOSTS=(
  10.50.216.13,
  10.73.146.15,
  10.92.215.12
)

NOW=$(date +'%Y%m%d-%H%M%S')
FULL_BACKUP_DIR=/etcd_backup/full/
DIFF_BACKUP_DIR=/etcd_backup/diff/
DIFF_BACKUP_OBJECT_STORAGE_BUCKET=s3://diff-backup
DIFF_BACKUP_S3CFG=~/.diff-s3cfg
LATEST_FULL_BACKUP=($( ls -tp ${FULL_BACKUP_DIR} | head -n 1))
UPDATED_FULL_BACKUP=${NOW}.json
DIFF_BACKUP=${NOW}.patch
BACKUP_ENDPOINT=/
RETAIN=14
PUBLIC_KEY_PEM=public_key.pem
USER=root

mkdir -p ${DIFF_BACKUP_DIR}

etcdtool --peers ${HOSTS} -u ${USER} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${UPDATED_FULL_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${DIFF_BACKUP} -out ${DIFF_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
diff ${LATEST_FULL_BACKUP} ${UPDATED_FULL_BACKUP} > ${DIFF_BACKUP}
s3cmd -c ${DIFF_BACKUP_S3CFG} put ${DIFF_BACKUP}.enc ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET}/${DIFF_BACKUP}.enc

# REMOVE OUTDATED BACKUP
DIFF_BACKUP_NUM=$(ls -l ${DIFF_BACKUP_DIR} | wc -l)

if ( ${DIFF_BACKUP_NUM} > ${RETAIN} )); then
  for BACKUP in $(ls -tp ${DIFF_BACKUP_DIR} | tail -n $(${DIFF_BACKUP_NUM} - ${RETAIN}) );
  do
    rm ${DIFF_BACKUP_DIR}/${BACKUP}
  done
fi
