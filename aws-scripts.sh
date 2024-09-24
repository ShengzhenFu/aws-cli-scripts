#!/bin/bash
# get short term credentials from sso
aws sso get-role-credentials --account-id 888888888888 --role-name AdministratorAccess --access-token xxxxxxxxxxxxxxxx --region us-west-2 --ca-bundle ./Cloudflare_Teams_CA.pem


# Athena query get result
aws athena start-query-execution --query-string \
  "SELECT bucket_name, requestdatetime, remoteip, operation, request_uri, httpstatus, requester \
   FROM s3_access_logs_db.mybucket_logs order by requestdatetime desc limit 100;" \
   --work-group "primary" \
   --result-configuration OutputLocation=s3://my-athena-query/ \
   --output=json | jq -r '.QueryExecutionId' | xargs aws athena get-query-results --query-execution-id


# get value from secret manager
aws secretmanager get-secret-value --secret-id testSecret \
  --profile dev-sso --region us-west-2 --output json | jq -r '.SecretString' | jq -r '.password'


# register on-premise instance to codeDeploy
# on priviledged machine
aws iam create-role --role-name CodeDeployOnPremiseInstanceRole --assume-role-policy-document file://CodeDeployRole.json --profile dev-sso
aws iam create-policy --policy-name CodeDeployOnPremiseInstancePolicy --policy-document file://CodeDeployPolicy.json --output text --query Policy.Arn --profile dev-sso
aws iam attach-role-policy --role-name CodeDeployOnPremiseInstanceRole --policy-arn arn:aws:iam:your-aws-account-id:policy/CodeDeployOnPremiseInstancePolicy --profile dev-sso
aws sts assume-role --role-arn arn:aws:iam::your-aws-account-id:role/CodeDeployOnPremiseInstanceRole --role-session-name on-premise --profile dev-sso
# copy the credentials to the on-premise instance ~/.aws/credentials
# install codeDeploy agent to the on-premise instance
# download codeDeploy STS helper to on-premise instance
sudo apt-get install ruby rubygems git
sudo gem install aws-sdk-core
git clone https://github.com/awslabs/aws-codedeploy-samples.git
cd aws-codedeploy-samples || exit
utilities/aws-codedeploy-session-helper/bin/get_sts_creds --role-arn arn:aws:iam::your-aws-account-id:role/CodeDeployOnPremiseInstanceRole --file ~/.aws/credentials
# create file /etc/codedeploy-agent/conf/codedeploy.onpremises.yml
cat > /etc/codedeploy-agent/conf/codedeploy.onpremises.yml <<EOF
---
iam_session_arn: arn:aws:sts::your-aws-account-id:assumed-role/CodeDeployOnPremiseInstanceRole/on-premise
aws_credentials_file: ~/.aws/credentials
region: us-west-2
EOF
#add cronjob
30 * * * * ~/aws-codedeploy-samples/utilities/aws-codedeploy-session-helper/bin/get_sts_creds --role-arn arn:aws:iam::your-aws-account-id:role/CodeDeployOnPremiseInstanceRole --file ~/.aws/credentials
systemctl restart codedeploy-agent
# on priviledged machine
aws deploy register-on-premises-instance --instance-name dev-instance --iam-sessdion-arn arn:aws:sts::your-aws-account-id:assumed-role/CodeDeployOnPremiseInstanceRole/on-premise --profile dev-sso
aws deploy add-tags-to-on-premises-instances --instance-names dev-instance--tags Key=Env,Value=OnPremise --profile dev-sso
# validate codedeploy logs
tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
ls -lrt /opt/codedeploy-agent/deployment-root
# CodeDeployRole.json
cat > CodeDeployRole.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
       }
    ]
}
EOF
# CodeDeployPolicy.json
cat > CodeDeployPolicy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name/*"
            ]
       }
    ]
}
EOF


# Check if bucket exists, auto create it if not exists
BUCKET=s3://your-bucket-name
echo "start checking bucket..."
aws s3 ls $BUCKET --profile dev-sso
if [[ ${?} -ne 0 ]]; then
  echo "bucket edoes not exists, creating it"
  aws s3 mb $BUCKET --profile dev-sso
  echo "bucket created"
else
  echo "bucket already exists"
fi


# find public s3
for bucket in $(aws s3api list-buckets --query 'Buckets[*].[Name]' --output text);
do
  if [[ $(aws s3api get-bucket-policy-status --bucket "$bucket" --query 'PolicyStatus.IsPublic' --output text 2>/dev/null) == True ]]; then
    echo "$bucket"
  fi
done
