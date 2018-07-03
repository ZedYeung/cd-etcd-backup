#!/bin/bash
source /etc/profile

NOW=$(date +'%Y%m%d-%H%M%S')
FULL_BACKUP=${NOW}.json
RETAIN=1
OBJECT_STORAGE_RETAIN=10

# https://gist.github.com/crazybyte/4142975
echo "BACKUP ${FULL_BACKUP}"
etcdtool --peers ${ENDPOINTS} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${FULL_BACKUP_DIR}/${FULL_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${FULL_BACKUP_DIR}/${FULL_BACKUP} -out ${FULL_BACKUP_DIR}/${FULL_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
# remove original backup once encrypt
rm ${FULL_BACKUP_DIR}/${FULL_BACKUP}
s3cmd put ${FULL_BACKUP_DIR}/${FULL_BACKUP}.enc ${FULL_BACKUP_OBJECT_STORAGE_BUCKET}/${FULL_BACKUP}.enc

OBJECT_STORAGE_NUM=$(s3cmd ls ${FULL_BACKUP_OBJECT_STORAGE_BUCKET} | wc -l)

if [ "${OBJECT_STORAGE_NUM}" -gt "${OBJECT_STORAGE_RETAIN}" ]; then
  echo "Remove outdated backup from object storage"
  for S3_BACKUP in $(s3cmd ls ${FULL_BACKUP_OBJECT_STORAGE_BUCKET} | head -n $[${OBJECT_STORAGE_NUM} - ${OBJECT_STORAGE_RETAIN}] | awk {'print $4'} );
    do
      s3cmd rm ${S3_BACKUP}
    done
fi

# REMOVE OUTDATED BACKUP
# ls -l | wc -l
# would have this extra line even in empty folder
# total 0
FULL_BACKUP_NUM=$[$(ls -l ${FULL_BACKUP_DIR} | wc -l) - 1]

if [ "${FULL_BACKUP_NUM}" -gt "${RETAIN}" ]; then
  echo "Remove outdated backup from local"
  for BACKUP in $(ls -tp ${FULL_BACKUP_DIR} | tail -n $[${FULL_BACKUP_NUM} - ${RETAIN}]);
    do
      rm ${FULL_BACKUP_DIR}/${BACKUP}
    done
fi
