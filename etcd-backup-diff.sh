#!/bin/bash
NOW=$(date +'%Y%m%d-%H%M%S')
FULL_BACKUP_DIR=/etcd_backup/full/
DIFF_BACKUP_DIR=/etcd_backup/diff/
DIFF_BACKUP_OBJECT_STORAGE_BUCKET=s3://diff-backup
LATEST_FULL_BACKUP=($( ls -tp ${FULL_BACKUP_DIR} | head -n 1))
UPDATED_FULL_BACKUP=${NOW}.json
DIFF_BACKUP=${NOW}.patch
BACKUP_ENDPOINT=/
RETAIN=3
PUBLIC_KEY_PEM=public_key.pem

echo "Backup ${DIFF_BACKUP}"
etcdtool --peers ${ENDPOINTS} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${UPDATED_FULL_BACKUP}
diff ${FULL_BACKUP_DIR}/${LATEST_FULL_BACKUP} ${UPDATED_FULL_BACKUP} > ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${DIFF_BACKUP_DIR}/${DIFF_BACKUP} -out ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
s3cmd put ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}.enc ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET}/${DIFF_BACKUP}.enc
rm ${UPDATED_FULL_BACKUP}

# REMOVE OUTDATED BACKUP
DIFF_BACKUP_NUM=$(ls -l ${DIFF_BACKUP_DIR} | wc -l)

if ( ${DIFF_BACKUP_NUM} > ${RETAIN} )); then
  echo "Remove outdated backup"
  for BACKUP in $(ls -tp ${DIFF_BACKUP_DIR} | tail -n $(${DIFF_BACKUP_NUM} - ${RETAIN}) );
  do
    rm ${DIFF_BACKUP_DIR}/${BACKUP}
  done
fi
