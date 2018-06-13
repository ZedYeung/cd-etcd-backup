#!/bin/bash
# openssl encrypt large file
# https://gist.github.com/crazybyte/4142975
TEST_FULL_NUM=1
TEST_DIFF_NUM=2
FULL_INTERVAL=600
DIFF_INTERVAL=120
GENERATE_INTERVAL=60
SLEEP_TIME=$(${TEST_FULL_NUM} * ${FULL_INTERVAL} + ${TEST_DIFF_NUM} * ${DIFF_INTERVAL})

openssl req -x509 -days 100000 -newkey rsa:8912 -keyout private_key.pem -out public_key.pem
./generate_random_data.sh &
# CRON JOB TO BACKUP
# https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
crontab -l > backup_cronjob
echo "*/10 * * * * ./etcd-backup-full.sh" >> backup_cronjob
echo "*/2 * * * * ./etcd-backup-diff.sh" >> backup_cronjob
# echo "* * * * * ./generate_random_data.sh" >> backup_cronjob
crontab backup_cronjob
rm backup_cronjob

sleep ${SLEEP_TIME}

# simulate clash
etcdctl rm / --recursive
# TODO SEND ALERT

LATEST_FULL_BACKUP=latest_full_backup.json
LATEST_DIFF_BACKUP=latest_diff_backup.patch

# TODO: DOWNLOAD ENC BACKUP FROM CLOUD STORAGE
openssl smime -decrypt -binary -in ${LATEST_FULL_BACKUP}.enc -inform DER -out ${LATEST_FULL_BACKUP} -inkey private_key.pem
openssl smime -decrypt -binary -in ${LATEST_DIFF_BACKUP}.enc -inform DER -out ${LATEST_DIFF_BACKUP} -inkey private_key.pem

# TEST FULL BACKUP
etcdtool --ca ./etcdcert.crt --peers host -u root import -y / ${LATEST_FULL_BACKUP}

FULL_BACKUP_TEST_CASE_NUM=$( ${TEST_FULL_NUM} * ${FULL_INTERVAL} / ${GENERATE_INTERVAL} )
assert $(etcdctl ls /test | wc -l) ${FULL_BACKUP_TEST_CASE_NUM}

for i in $(seq 1 ${FULL_BACKUP_TEST_CASE_NUM});
  do
    # deployment=nginx${i}
    # assert $(etcdctl get /registry/deployments/${deployment})
    assert $(etcdctl get /test/case${i}) $(${i} * 2 - 1)


# TEST DIFF BACKUP
UPDATED_BACKUP=updated_backup.json
patch ${LATEST_FULL_BACKUP} -i ${LATEST_DIFF_BACKUP} -o ${UPDATED_BACKUP}

etcdtool --ca ./etcdcert.crt --peers host -u root import -y / ${UPDATED_BACKUP}

DIFF_BACKUP_TEST_CASE_NUM=$(${SLEEP_TIME} / ${GENERATE_INTERVAL} )
assert $(etcdctl ls /test | wc -l) ${DIFF_BACKUP_TEST_CASE_NUM}

for i in $(seq 1 ${DIFF_BACKUP_TEST_CASE_NUM});
  do
    assert $(etcdctl get /test/case${i}) $(${i} * 2 - 1)
