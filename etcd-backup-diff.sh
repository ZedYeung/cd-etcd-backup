#!/bin/bash
HOSTS=(

)

NOW=$(date +'%Y%m%d-%H%M%S')
BACKUP_DIR=/etcd_backup/diff/
RETAIN=14
LATEST_BACKUP_FILE=($( ls -tp /etcd_backup/full/ | head -n 1))

for HOST in HOSTS;
do
  UPDATED_FILE="${HOST}${NOW}.json"
  BACKUP_FILE="${HOST}${NOW}.patch"
  mkdir -p ${BACKUP_DIR}
  etcdtool --ca ./etcdcert.crt --peers host -u root export /registry -f 'JSON' -o ${UPDATED_FILE}
  openssl smime -encrypt -binary -aes-256-cbc -in ${BACKUP_FILE} -out ${BACKUP_FILE}.enc -outform DER public_key.pem
  diff ${LATEST_BACKUP_FILE} ${UPDATED_FILE} > ${BACKUP_FILE}
done

BACKUP_NUM=$(ls -l ${BACKUP_DIR} | wc -l)

if ( ${BACKUP_NUM} > ${RETAIN} ));
then
  for BACKUP in $(ls -tp ${BACKUP_DIR} | tail -n (${BACKUP_NUM} - ${RETAIN}) );
    do
      rm ${BACKUP_DIR}/${BACKUP}
    done
fi
