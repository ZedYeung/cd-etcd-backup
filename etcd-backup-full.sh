#!/bin/bash
NOW=$(date +'%Y%m%d-%H%M%S')
FULL_BACKUP_DIR=/etcd_backup/full/
FULL_BACKUP_OBJECT_STORAGE_BUCKET=s3://full-backup
FULL_BACKUP=${NOW}.json
BACKUP_ENDPOINT=/
RETAIN=1
PUBLIC_KEY_PEM=~/cd-etcd-backup/public_key.pem

# https://gist.github.com/crazybyte/4142975
curl -X POST -H 'Content-type: application/json' --data '{"text": "Backup '"${FULL_BACKUP}"' "}' ${SLACK_APP}
etcdtool --peers ${ENDPOINTS} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${FULL_BACKUP_DIR}/${FULL_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${FULL_BACKUP_DIR}/${FULL_BACKUP} -out ${FULL_BACKUP_DIR}/${FULL_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
# remove original backup once encrypt
rm ${FULL_BACKUP_DIR}/${FULL_BACKUP}
s3cmd put ${FULL_BACKUP_DIR}/${FULL_BACKUP}.enc ${FULL_BACKUP_OBJECT_STORAGE_BUCKET}/${FULL_BACKUP}.enc

# REMOVE OUTDATED BACKUP
# ls -l | wc -l
# would have this extra line even in empty folder
# total 0
FULL_BACKUP_NUM=$[$(ls -l ${FULL_BACKUP_DIR} | wc -l) - 1]

if [ "${FULL_BACKUP_NUM}" -gt "${RETAIN}" ]; then
  curl -X POST -H 'Content-type: application/json' --data '{"text": "FULL_BACKUP_NUM: '"${FULL_BACKUP_NUM}"' "}' ${SLACK_APP}
  for BACKUP in $(ls -tp ${FULL_BACKUP_DIR} | tail -n $[${FULL_BACKUP_NUM} - ${RETAIN}]);
    do
      rm ${FULL_BACKUP_DIR}/${BACKUP}
    done
fi
