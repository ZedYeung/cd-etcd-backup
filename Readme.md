# ETCD BACKUP

## Backup and Restore Tool
[etcdtool](https://www.compose.com/articles/backups-etcd-and-etcdtool/)

## Encryption
[OPENSSL SMIME](https://gist.github.com/crazybyte/4142975)
Store the private key in isolated disk

## Storage
[Object Storage](https://www.ctl.io/object-storage/)
[S3CMD](https://www.ctl.io/knowledge-base/object-storage/s3cmd-object-storage-management-for-linux-machines/)

## Alert
Use Slack webhook
```
curl -L ${HOST}/health
curl -X POST -H 'Content-type: application/json' --data '{"text": "${HOST} down"}' ${SLACK_APP}
```

## Cronjob
Backup full every week   
Backup increment every half day
Interrogate cluster machines every minute. Email one alert for each unhealthy machine.

## How to backup
1. Modify .s3cfg with your own Object Storage account information
2. Modify according environment variable in set_env_variable.sh and run it
3. Modify cronjob schedule in backup_cronjob and run start-backup-cronjob.sh
4. run start-backup-cronjob.sh

## How to restore
Modify according argument in restore.sh and run it


## Test

### Test case
Generate one key value pair every minute with incremental index i.  
Simulate clash at some time point by removing the root directory of etcd.  
Restore full backup and diff backup and check the consistency respectively.  
Assert etcd get key equal value and the total number of key value pair.

### How to test
1. Launch a new VM in CA3, clone this repo.
2. Install required dependencies with install-dependencies.sh
3. Setup environment with set_env_variable.sh(probably need to reboot if source not work)
4. Run test.sh

## To do
### Test large backup
### fix: curl /health is not a good way to detect cluster health, it always return unhealth even the cluster works well due to busy.
