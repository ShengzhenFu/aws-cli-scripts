#!/bin/bash
########################################################
# Auther: Shengzhen
# The script is to retrieve AWS short lived credentials
########################################################

temp_cred_file="/root/.aws/temp_creds"
cred_file="/root/.aws/credentials"
export HOME=/root
export AWS_CONFIG_FILE="/root/.aws/config"
export AWS_SHARED_CREDENTIALS_FILE="/root/.aws/credentials"
export AWS_DEFAULT_REGION=us-west-2
echo "aws sts $(date)"
response=$(/usr/local/bin/aws sts assume-role --role-arn arn:aws:iam::yourAwsAccountId:role/CodeDeployOnPremiseInstanceRole --role-session-name on-premise --output json)
error_code=${?}
if [[ $error_code -ne 0 ]]; then
    echo "aws cli error ${error_code}"
    return 1
fi
echo "$response" > ${temp_cred_file}
echo "successully write short lived credentials to temp file ${temp_cred_file} ! $(date)"
sleep 3
# get values from temp file
access_key_id=$(cat ${temp_cred_file} | jq -r ".Credentials.AccessKeyId")
access_secret_key=$(cat ${temp_cred_file} | jq -r ".Credentials.SecretAccessKey")
session_token=$(cat ${temp_cred_file} | jq -r ".Credentials.SessionToken")
if [ -z "$access_key_id" ] || [ -z "$access_secret_key" ] || [ -z "$session_token" ]; then
    echo "some creds is null, stop update ! $(date)"
    exit 1
else
  # update the credentials file with the latest value from Aws Sts
  sed -i "2s/.*/aws_access_key_id=${access_key_id}/" ${cred_file}
  sed -i "3s#.*#aws_secret_access_key=${access_secret_key}#" ${cred_file}
  sed -i "4s#.*#aws_session_token=${session_token}#" ${cred_file}
  echo "short lived credentials updated successully ! $(date)"
fi
exit 0

# cronjob
# */15 * * * * /root/set-creds.sh >> /var/log/cron.log && echo "update sts credentials at $(date +\%Y\%m\%d_\%H\%M\%SZ)" >> /var/log/cron.log 2>&1
