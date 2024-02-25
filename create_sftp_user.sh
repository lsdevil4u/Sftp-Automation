#!/bin/bash

# Input parameters
username=$1

# Create SSH key pair
ssh-keygen -t rsa -b 2048 -f /tmp/$username -N "" -C "$username@yourcompany.com"

# Extract public key
ssh_public_key=$(cat /tmp/$username.pub)

# Replace 'your-iam-role-arn' with the actual ARN of your IAM role
iam_role_arn="arn:aws:iam::660262893273:role/sftp-role"

# Create SFTP user
aws transfer create-user --server-id s-efd3d35baf264f6da --user-name $username --role $iam_role_arn --ssh-public-key-body "$ssh_public_key"

# Get public SSH key
#ssh_key=$(aws transfer describe-user --server-id s-efd3d35baf264f6da --user-name $username --query 'User.SshPublicKeys[0]' --output text)

# Upload public SSH key to S3 bucket
#echo "$ssh_key" > /tmp/$username.pub
aws s3 cp /tmp/$username.pub s3://s3glacier-test1-dest/$username.pub
