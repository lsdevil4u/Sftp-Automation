#!/bin/bash

# Input parameters
username=$1

# Create SFTP user
aws transfer create-user --server-id your-server-id --user-name $username

# Get public SSH key
ssh_key=$(aws transfer describe-user --server-id your-server-id --user-name $username --query 'User.SshPublicKeys[0]' --output text)

# Upload public SSH key to S3 bucket
echo "$ssh_key" > /tmp/$username.pub
aws s3 cp /tmp/$username.pub s3://your-s3-bucket/$username.pub
