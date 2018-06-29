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
PUBLIC_KEY_PEM=~/cd-etcd-backup/public_key.pem

curl -X POST -H 'Content-type: application/json' --data '{"text": "Backup '"${DIFF_BACKUP}"' "}' ${SLACK_APP}
etcdtool --peers ${ENDPOINTS} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${UPDATED_FULL_BACKUP}
diff ${FULL_BACKUP_DIR}/${LATEST_FULL_BACKUP} ${UPDATED_FULL_BACKUP} > ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${DIFF_BACKUP_DIR}/${DIFF_BACKUP} -out ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
# remove original backup once encrypt
rm ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}
s3cmd put ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}.enc ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET}/${DIFF_BACKUP}.enc
rm ${UPDATED_FULL_BACKUP}

# REMOVE OUTDATED BACKUP
# ls -l | wc -l
# would have this extra line even in empty folder
# total 0
DIFF_BACKUP_NUM=$[$(ls -l ${DIFF_BACKUP_DIR} | wc -l) - 1]

if [ "${DIFF_BACKUP_NUM}" -gt "${RETAIN}" ]; then
  curl -X POST -H 'Content-type: application/json' --data '{"text": "DIFF_BACKUP_NUM: '"${DIFF_BACKUP_NUM}"' "}' ${SLACK_APP}
  for BACKUP in $(ls -tp ${DIFF_BACKUP_DIR} | tail -n $[${DIFF_BACKUP_NUM} - ${RETAIN}]);
  do
    rm ${DIFF_BACKUP_DIR}/${BACKUP}
  done
fi
