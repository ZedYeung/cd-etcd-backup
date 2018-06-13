# ETCD BACKUP

## Backup and Restore Tool
[etcdtool](https://www.compose.com/articles/backups-etcd-and-etcdtool/)

## Encryption
[OPENSSL SMIME](https://gist.github.com/crazybyte/4142975)

## VPN Connection
TODO

## Storage
[Object Storage](https://www.ctl.io/object-storage/)

## Alert
```
curl -L ${HOST}/health
```

## Cronjob
Backup full every week   
Backup increment every half day
Interrogate cluster machines every minute. Email one alert for each unhealthy machine.

## Test
Generate one key value pair every minute. Simulate clash at some time point.
Restore full backup and diff backup and check the consistency respectively.
