#!/bin/bash
# openssl encrypt large file
# https://gist.github.com/crazybyte/4142975
RESTORE_HOST0=10.103.1.13
RESTORE_HOST1=10.103.1.14
RESTORE_HOST2=10.103.1.15
HOST0=10.103.1.16
HOST1=10.103.1.17
HOST2=10.103.1.18
PORT=2379

export RESTORE_ENDPOINTS="http://${RESTORE_HOST0}:${PORT},http://${RESTORE_HOST1}:${PORT},http://${RESTORE_HOST2}:${PORT}"
export ENDPOINTS="http://${HOST0}:${PORT},http://${HOST1}:${PORT},http://${HOST2}:${PORT}"

TEST_FULL_NUM=1
TEST_DIFF_NUM=2
FULL_INTERVAL=600
DIFF_INTERVAL=120
GENERATE_INTERVAL=60
FULL_BACKUP_OBJECT_STORAGE_BUCKET=s3://full-backup
DIFF_BACKUP_OBJECT_STORAGE_BUCKET=s3://diff-backup
BACKUP_ENDPOINT=/
PRIVATE_KEY_PEM=private_key.pem
SLEEP_TIME=$[${TEST_FULL_NUM} * ${FULL_INTERVAL} + ${TEST_DIFF_NUM} * ${DIFF_INTERVAL}]

echo "Generate ssl file..."
openssl req -x509 -days 100000 -newkey rsa:8912 -keyout private_key.pem -out public_key.pem
./generate_random_data.sh &

# CRON JOB TO BACKUP
# https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
echo "Create cronjob..."
crontab -l > backup_cronjob
echo "*/10 * * * * ./etcd-backup-full.sh" >> backup_cronjob
echo "*/2 * * * * ./etcd-backup-diff.sh" >> backup_cronjob
echo "* * * * * ./etcd_unhealth_alert.sh" >> backup_cronjob
# echo "* * * * * ./generate_random_data.sh" >> backup_cronjob
crontab backup_cronjob
# rm backup_cronjob

echo "Backup..."
sleep ${SLEEP_TIME}

# simulate clash
# etcdctl rm ${BACKUP_ENDPOINT} --recursive
# TODO VPN CONNECT
echo "Restore..."
LATEST_FULL_ENC_BACKUP=$(s3cmd ls ${FULL_BACKUP_OBJECT_STORAGE_BUCKET} | head -n 1)
LATEST_DIFF_ENC_BACKUP=$(s3cmd ls ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET} | head -n 1)
LATEST_FULL_BACKUP=$(${LATEST_FULL_ENC_BACKUP} | rev | cut -f 2- -d '.' | rev)
LATEST_DIFF_BACKUP=$(${LATEST_DIFF_ENC_BACKUP} | rev | cut -f 2- -d '.' | rev)

s3cmd get ${FULL_BACKUP_OBJECT_STORAGE_BUCKET}/${LATEST_FULL_ENC_BACKUP} ${LATEST_FULL_ENC_BACKUP}
s3cmd get ${DIFF_BACKUP_OBJECT_STORAGE_BUCKET}/${LATEST_DIFF_ENC_BACKUP} ${LATEST_DIFF_ENC_BACKUP}

openssl smime -decrypt -binary -in ${LATEST_FULL_ENC_BACKUP} -inform DER -out ${LATEST_FULL_BACKUP} -inkey ${PRIVATE_KEY_PEM}
openssl smime -decrypt -binary -in ${LATEST_DIFF_ENC_BACKUP} -inform DER -out ${LATEST_DIFF_BACKUP} -inkey ${PRIVATE_KEY_PEM}

# TEST FULL BACKUP
# TODO: CA
etcdtool --peers ${RESTORE_ENDPOINTS} import -y ${BACKUP_ENDPOINT} ${LATEST_FULL_BACKUP}

FULL_BACKUP_TEST_CASE_NUM=$( ${TEST_FULL_NUM} * ${FULL_INTERVAL} / ${GENERATE_INTERVAL} )
assert $(etcdctl ls /test | wc -l) ${FULL_BACKUP_TEST_CASE_NUM}

for i in $(seq 1 ${FULL_BACKUP_TEST_CASE_NUM});
do
  # deployment=nginx${i}
  # assert $(etcdctl get /registry/deployments/${deployment})
  assert $(etcdctl get /test/case${i}) $[${i} * 2 - 1]
done


# TEST DIFF BACKUP
UPDATED_FULL_BACKUP=updated_full_backup.json
patch ${LATEST_FULL_BACKUP} -i ${LATEST_DIFF_BACKUP} -o ${UPDATED_FULL_BACKUP}

etcdtool --peers ${RESTORE_ENDPOINTS} import -y ${BACKUP_ENDPOINT} ${UPDATED_FULL_BACKUP}

DIFF_BACKUP_TEST_CASE_NUM=$(${SLEEP_TIME} / ${GENERATE_INTERVAL} )
assert $(etcdctl ls /test | wc -l) ${DIFF_BACKUP_TEST_CASE_NUM}

for i in $(seq 1 ${DIFF_BACKUP_TEST_CASE_NUM});
do
  assert $(etcdctl get /test/case${i}) $[${i} * 2 - 1]
done
