#!/bin/bash
RESTORE_HOST0=10.103.1.13
RESTORE_HOST1=10.103.1.14
RESTORE_HOST2=10.103.1.15
PORT=2379
RESTORE_ENDPOINTS="http://${RESTORE_HOST0}:${PORT},http://${RESTORE_HOST1}:${PORT},http://${RESTORE_HOST2}:${PORT}"

echo "Restoring..."
# s3cmd output sample
# 2018-06-28 22:47      3576   s3://full-backup/test.sh
LATEST_FULL_ENC_BACKUP=$(basename $(s3cmd ls ${FULL_BACKUP_OBJECT_STORAGE_BUCKET} | tail -n 1 | awk {'print $4'}))
LATEST_DIFF_ENC_BACKUP=$(basename $(s3cmd ls ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET} | tail -n 1 | awk {'print $4'}))
LATEST_FULL_BACKUP=$(basename ${LATEST_FULL_ENC_BACKUP} .enc)
LATEST_DIFF_BACKUP=$(basename ${LATEST_DIFF_ENC_BACKUP} .enc)

echo "Pulling ${LATEST_FULL_ENC_BACKUP}"
s3cmd get ${FULL_BACKUP_OBJECT_STORAGE_BUCKET}/${LATEST_FULL_ENC_BACKUP} ${LATEST_FULL_ENC_BACKUP}
echo "Pulling ${LATEST_DIFF_ENC_BACKUP}"
s3cmd get ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET}/${LATEST_DIFF_ENC_BACKUP} ${LATEST_DIFF_ENC_BACKUP}

echo "Descrypting..."
openssl smime -decrypt -binary -in ${LATEST_FULL_ENC_BACKUP} -inform DER -out ${LATEST_FULL_BACKUP} -inkey ${PRIVATE_KEY_PEM}
openssl smime -decrypt -binary -in ${LATEST_DIFF_ENC_BACKUP} -inform DER -out ${LATEST_DIFF_BACKUP} -inkey ${PRIVATE_KEY_PEM}

echo "Recovering..."
FULL_BACKUP_TIMESTAMP=$(date -d @$(basename ${LATEST_FULL_BACKUP} .json) +"%Y%m%d-%H%M%S")
DIFF_BACKUP_TIMESTAMP=$(date -d @$(basename ${LATEST_DIFF_BACKUP} .patch) +"%Y%m%d-%H%M%S")
PATCH_FULL_BACKUP=patch_full_backup.json
# make sure diff-backup is newer than full-backup otherwise patch is meaningless
if [ ${DIFF_BACKUP_TIMESTAMP} -ge ${FULL_BACKUP_TIMESTAMP} ]; then
  patch ${LATEST_FULL_BACKUP} -i ${LATEST_DIFF_BACKUP} -o ${PATCH_FULL_BACKUP}
  etcdtool --peers ${RESTORE_ENDPOINTS} import -y ${BACKUP_ENDPOINT} ${PATCH_FULL_BACKUP}
else
  etcdtool --peers ${RESTORE_ENDPOINTS} import -y ${BACKUP_ENDPOINT} ${LATEST_FULL_BACKUP}
fi
