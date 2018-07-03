#!/bin/bash
# openssl encrypt large file
# https://gist.github.com/crazybyte/4142975
echo "Setup environment variable"
mkdir -p /etcd_backup/full/
mkdir -p /etcd_backup/diff/

cp ./.s3cfg ~/.s3cfg

cat>~/test_env.sh<<EOF
#!/bin/bash
export SLACK_APP="https://hooks.slack.com/services/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"
export HOST0=10.103.1.16
export HOST1=10.103.1.17
export HOST2=10.103.1.18
export PORT=2379
export ENDPOINTS="http://${HOST0}:${PORT},http://${HOST1}:${PORT},http://${HOST2}:${PORT}"
export FULL_BACKUP_OBJECT_STORAGE_BUCKET=s3://full-backup
export DIFF_BACKUP_OBJECT_STORAGE_BUCKET=s3://diff-backup
export FULL_BACKUP_DIR=/etcd_backup/full/
export DIFF_BACKUP_DIR=/etcd_backup/diff/
export PRIVATE_KEY_PEM=~/.ssh/backup_private_key.pem
export PUBLIC_KEY_PEM=~/.ssh/backup_public_key.pem
export BACKUP_ENDPOINT=/
EOF

source /etc/profile

# used in generate_random_data.sh
export GENERATE_INTERVAL=10

TEST_FULL_NUM=2
TEST_NUM=2
FULL_INTERVAL=180
INTERVAL=60
CUSHION_INTERVAL=10

SLEEP_TIME=$[${TEST_FULL_NUM} * ${FULL_INTERVAL} + ${TEST_NUM} * ${INTERVAL} + ${CUSHION_INTERVAL}]

echo "Generate ssl file..."
openssl req -x509 -days 100000 -newkey rsa:4096 -keyout ${PRIVATE_KEY_PEM} -out ${PUBLIC_KEY_PEM}

echo "Generate data..."
./generate_random_data.sh &

# CRON JOB TO BACKUP
# https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
echo "Create cronjob..."
# echo "* * * * * ./generate_random_data.sh" >> backup_cronjob
crontab backup_cronjob
# rm backup_cronjob

echo "Backup..."
sleep ${SLEEP_TIME}

# simulate clash
# etcdctl rm ${BACKUP_ENDPOINT} --recursive
# TODO VPN CONNECT
echo "Restore..."
./restore.sh

BACKUP_TEST_CASE_NUM=$[ (${TEST_FULL_NUM} * ${FULL_INTERVAL} + ${TEST_NUM} * ${INTERVAL}) / ${GENERATE_INTERVAL}]
RESTORE_BACKUP_NUM=$(etcdctl --endpoints ${RESTORE_ENDPOINTS} ls /test | wc -l)
if  [ ${RESTORE_BACKUP_NUM} -ne ${BACKUP_TEST_CASE_NUM} ]; then
  echo "Backup test case number: ${BACKUP_TEST_CASE_NUM}"
  echo "Restore backup test case number: ${RESTORE_BACKUP_NUM}"
fi

for i in $(seq 1 ${BACKUP_TEST_CASE_NUM});
do
  if [ "$(etcdctl --endpoints ${RESTORE_ENDPOINTS} get /test/case${i})" -ne $[${i} * 2 - 1] ]; then
    echo "mismatch"
  fi
done
