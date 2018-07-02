#!/bin/bash
echo "Setup environment variable"
./set_env_variable.sh

echo "Generate ssl file..."
openssl req -x509 -days 100000 -newkey rsa:4096 -keyout ${PRIVATE_KEY_PEM} -out ${PUBLIC_KEY_PEM}

# CRON JOB TO BACKUP
# https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
echo "Create cronjob..."
crontab backup_cronjob
