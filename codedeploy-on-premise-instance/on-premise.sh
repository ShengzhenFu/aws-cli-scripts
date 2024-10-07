# https://docs.aws.amazon.com/codedeploy/latest/userguide/register-on-premise-instance-iam-session-arn.html
# run below commands on your computer
aws iam create-role --role-name CodeDeployOnPremiseInstanceRole --assume-role-policy-document file://CodeDeployRole.json --profile default --region us-west-2

aws iam create-policy --policy-name CodeDeployOnPremiseInstancePolicy --policy-document file://CodeDeployPolicy.json --profile default --region us-west-2

aws iam attach-role-policy --role-name CodeDeployOnPremiseInstanceRole --policy-arn arn:aws:iam::yourAwsAccountId:policy/CodeDeployOnPremiseInstancePolicy --profile default --region us-west-2

aws sts assume-role --role-arn arn:aws:iam::yourAwsAccountId:role/CodeDeployOnPremiseInstanceRole --role-session-name on-premise --profile default --region us-west-2

# login to the on-premise instance, install codedeploy agent if needed
# https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html
systemctl stop codedeploy-agent
# copy the credentials to the on-premise instance, ~/.aws/credentials
aws sts assume-role --role-arn arn:aws:iam::yourAwsAccountId:role/CodeDeployOnPremiseInstanceRole --role-session-name on-premise

cat > /etc/codedeploy-agent/conf/codedeploy.onpremise.yml <<EOF
---
iam_session_arn: arn:aws:sts::yourAwsAccountId:assume-role/CodeDeployOnPremiseInstanceRole/on-premise
aws_credentials_file: /root/.aws/credentials
region: us-west-2
EOF

# register on-premise instance on your computer
aws deploy register-on-premise-instance --instance-name dev-onpremise --iam-session-arn arn:aws:sts::yourAwsAccountId:assumed-role/CodeDeployOnPremiseInstanceRole/on-premise --profile default
aws deploy add-tags-to-on-premise-instances --instance-names dev-onpremise --tags Key=Env,Value=OnPremise --profile default

# check codedeploy logs
tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
ls -lrt /opt/codedeploy-agent/deploy-root

systemctl restart codedeploy-agent
