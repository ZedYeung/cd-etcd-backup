#!/bin/bash
source /etc/profile

NOW=$(date +'%Y%m%d-%H%M%S')
LATEST_FULL_BACKUP=($( ls -tp ${FULL_BACKUP_DIR} | head -n 1))
PATCH_FULL_BACKUP=${NOW}.json
DIFF_BACKUP=${NOW}.patch
RETAIN=3
OBJECT_STORAGE_RETAIN=10

# if there is no full backup, diff backup would not work
if [ -z "$(ls -A ${FULL_BACKUP_DIR})" ]; then
  echo "No full backup is detected"
  exit
fi

echo "BACKUP ${DIFF_BACKUP}"
etcdtool --peers ${ENDPOINTS} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${PATCH_FULL_BACKUP}
diff ${FULL_BACKUP_DIR}/${LATEST_FULL_BACKUP} ${PATCH_FULL_BACKUP} > ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${DIFF_BACKUP_DIR}/${DIFF_BACKUP} -out ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
# remove original backup once encrypt
rm ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}
s3cmd put ${DIFF_BACKUP_DIR}/${DIFF_BACKUP}.enc ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET}/${DIFF_BACKUP}.enc
rm ${PATCH_FULL_BACKUP}

OBJECT_STORAGE_NUM=$(s3cmd ls ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET} | wc -l)

if [ "${OBJECT_STORAGE_NUM}" -gt "${OBJECT_STORAGE_RETAIN}" ]; then
  echo "Remove outdated backup from object storage"
  for S3_BACKUP in $(s3cmd ls ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET} | head -n $[${OBJECT_STORAGE_NUM} - ${OBJECT_STORAGE_RETAIN}] | awk {'print $4'} );
    do
      s3cmd rm ${S3_BACKUP}
    done
fi

# REMOVE OUTDATED BACKUP
# ls -l | wc -l
# would have this extra line even in empty folder
# total 0
DIFF_BACKUP_NUM=$[$(ls -l ${DIFF_BACKUP_DIR} | wc -l) - 1]

if [ "${DIFF_BACKUP_NUM}" -gt "${RETAIN}" ]; then
  echo "Remove outdated backup from local"
  for BACKUP in $(ls -tp ${DIFF_BACKUP_DIR} | tail -n $[${DIFF_BACKUP_NUM} - ${RETAIN}]);
  do
    rm ${DIFF_BACKUP_DIR}/${BACKUP}
  done
fi
