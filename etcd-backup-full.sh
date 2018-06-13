#!/bin/bash
HOSTS=(

)

NOW=$(date +'%Y%m%d-%H%M%S')
FULL_BACKUP_DIR=/etcd_backup/full/
FULL_BACKUP_OBJECT_STORAGE_BUCKET=s3://full-backup
FULL_BACKUP=${HOST}-${NOW}.json
BACKUP_ENDPOINT=/
RETAIN=1
CRT=""
PUBLIC_KEY_PEM=public_key.pem
USER=root

mkdir -p ${FULL_BACKUP_DIR}

# https://gist.github.com/crazybyte/4142975
etcdtool --ca ${CRT} --peers ${HOSTS} -u ${USER} export ${BACKUP_ENDPOINT} -f 'JSON' -o ${FULL_BACKUP_DIR}/${FULL_BACKUP}
openssl smime -encrypt -binary -aes-256-cbc -in ${FULL_BACKUP} -out ${FULL_BACKUP}.enc -outform DER ${PUBLIC_KEY_PEM}
s3cmd put ${FULL_BACKUP}.enc ${FULL_BACKUP_OBJECT_STORAGE_BUCKET}/${FULL_BACKUP}.enc

# REMOVE OUTDATED BACKUP
FULL_BACKUP_NUM=$(ls -l ${FULL_BACKUP_DIR} | wc -l)

if ( ${FULL_BACKUP_NUM} > ${RETAIN} )); then
  for BACKUP in $(ls -tp ${FULL_BACKUP_DIR} | tail -n $(${FULL_BACKUP_NUM} - ${RETAIN}) );
    do
      rm ${FULL_BACKUP_DIR}/${BACKUP}
    done
fi
