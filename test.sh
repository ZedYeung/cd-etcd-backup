#!/bin/bash
TEST_FULL_NUM=10
TEST_DIFF_NUM=2
INTERVAL=60
SLEEP_TIME=(${TEST_FULL_NUM} + ${TEST_DIFF_NUM}) * ${INTERVAL}
etcdctl ls /registry --recursive

openssl req -x509 -days 100000 -newkey rsa:8912 -keyout private_key.pem -out public_key.pem
./generate_random_data.sh

sleep ${SLEEP_TIME}

etcdctl rm /registry --recursive

LATEST_FULL_BACKUP=latest_full_backup.json
LATEST_DIFF_BACKUP=latest_diff_backup.patch

# TODO: DOWNLOAD ENC BACKUP FROM CLOUD STORAGE
openssl smime -decrypt -binary -in ${LATEST_FULL_BACKUP}.enc -inform DER -out ${LATEST_FULL_BACKUP} -inkey private_key.pem
openssl smime -decrypt -binary -in ${LATEST_DIFF_BACKUP}.enc -inform DER -out ${LATEST_DIFF_BACKUP} -inkey private_key.pem

# TEST FULL BACKUP
etcdtool --ca ./etcdcert.crt --peers host -u root import -y /registry ${LATEST_FULL_BACKUP}
for i in $(seq 1 ${TEST_FULL_NUM});
  do
    deployment=nginx${i}
    value=$(etcdctl get /registry/deployments/${deployment})
    assert ${value}

# TEST DIFF BACKUP
UPDATED_BACKUP=updated_backup.json
patch ${LATEST_FULL_BACKUP} -i ${LATEST_DIFF_BACKUP} -o ${UPDATED_BACKUP}

etcdtool --ca ./etcdcert.crt --peers host -u root import -y /registry ${UPDATED_BACKUP}

for i in $(seq 1 (${TEST_FULL_NUM} + ${TEST_DIFF_NUM}));
  do
    deployment=nginx${i}
    value=$(etcdctl get /registry/deployments/${deployment})
    assert ${value}
