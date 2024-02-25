#!/bin/bash

# Input parameters
username=$1

# Create SFTP user
aws transfer create-user --server-id s-efd3d35baf264f6da --user-name $username

# Get public SSH key
ssh_key=$(aws transfer describe-user --server-id s-efd3d35baf264f6da --user-name $username --query 'User.SshPublicKeys[0]' --output text)

# Upload public SSH key to S3 bucket
echo "$ssh_key" > /tmp/$username.pub
aws s3 cp /tmp/$username.pub s3://s3glacier-test1-dest/$username.pub
