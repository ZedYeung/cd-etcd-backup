# ETCD BACKUP

## Backup and Restore Tool
[etcdtool](https://www.compose.com/articles/backups-etcd-and-etcdtool/)

## Encryption
[OPENSSL SMIME](https://gist.github.com/crazybyte/4142975)

## VPN Connection
TODO

## Storage
[Object Storage](https://www.ctl.io/object-storage/)
[S3CMD](https://www.ctl.io/knowledge-base/object-storage/s3cmd-object-storage-management-for-linux-machines/)

## Alert
```
curl -L ${HOST}/health
```

## Cronjob
Backup full every week   
Backup increment every half day
Interrogate cluster machines every minute. Email one alert for each unhealthy machine.

## Test
Generate one key value pair every minute with incremental index i.  
Simulate clash at some time point by removing the root directory of etcd.  
Restore full backup and diff backup and check the consistency respectively.  
Assert etcd get key equal value and the total number of key value pair.

## Test large backup
TODO
