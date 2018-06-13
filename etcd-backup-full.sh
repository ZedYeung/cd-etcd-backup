#!/bin/bash
HOSTS=(

)

NOW=$(date +'%Y%m%d-%H%M%S')
BACKUP_DIR=/etcd_backup/full/
RETAIN=1
CRT=

for HOST in HOSTS;
do
# https://gist.github.com/crazybyte/4142975
  BACKUP_FILE="${HOST}${NOW}.json"
  mkdir -p ${BACKUP_DIR}
  etcdtool --ca ${CRT} --peers ${HOST} -u root export /registry -f 'JSON' -o ${BACKUP_DIR}/${BACKUP_FILE}
  openssl smime -encrypt -binary -aes-256-cbc -in ${BACKUP_FILE} -out ${BACKUP_FILE}.enc -outform DER public_key.pem
  # todo: upload to cloud storage
  # remove the old one
done

BACKUP_NUM=$(ls -l ${BACKUP_DIR} | wc -l)

if ( ${BACKUP_NUM} > ${RETAIN} )); then
  for BACKUP in $(ls -tp ${BACKUP_DIR} | tail -n (${BACKUP_NUM} - ${RETAIN}) );
    do
      rm ${BACKUP_DIR}/${BACKUP}
    done
fi
