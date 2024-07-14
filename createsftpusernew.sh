#!/bin/bash

set -e

DELETION_D=$(if [[ -z "${DELETION_DATE}" ]]; then echo $(date +'%Y-%m-%d' -d "$(date) + 90 day") ; else echo ${DELETION_DATE} ; fi)
USER=${USERNAME}
SSH_PATH=/opt/sftp-keys/$USER

# Create the parent directory if it doesn't exist
if [ ! -d "/opt/sftp-keys" ]; then
    sudo mkdir -p /opt/sftp-keys
fi

/usr/bin/rm -rf $SSH_PATH
/usr/bin/mkdir $SSH_PATH
/usr/bin/ssh-keygen -t rsa -b 4096 -C "$USER" -f $SSH_PATH/$USER -q -N ""

# installation of puttygen
sudo apt update
sudo apt install putty-tools

/usr/bin/puttygen  $SSH_PATH/$USER -o $SSH_PATH/$USER.ppk

# aws-cli installation
sudo apt update
sudo apt install awscli
which aws
aws --version

/usr/bin/aws s3 sync /opt/sftp-keys/ s3://testing-buket/ --sse --region us-east-1

# Initialize an array to store individual policy statements
policy_statements=()
bucket_arns=()

# Loop over each line in LOCATIONS and generate policy statements
while IFS=', ' read -r bucket path permission; do
  echo "Bucket Name: $bucket"
  echo "Path: $path"
  echo "Permission: $permission"
  echo "---"  # Separator between each entry
  if [[ "${permission}" == "RO" ]]; then
    POLICY_ACTION="\"s3:GetObject*\""
  elif [[ "${permission}" == "RW" ]]; then
    POLICY_ACTION="\"s3:PutObject*\",\"s3:GetObject*\""
  elif [[ "${permission}" == "RWD" ]]; then
    POLICY_ACTION="\"s3:PutObject*\",\"s3:GetObject*\",\"s3:DeleteObject*\""
  else
    echo "Invalid permission value. Valid values are: RO, RW, RWD."
    exit 1
  fi
  bucket_arns+=("\"arn:aws:s3:::$bucket\"")
  policy_statement="{\"Effect\":\"Allow\",\"Action\":[$POLICY_ACTION],\"Resource\":\"arn:aws:s3:::$bucket\/$path\/*\"}"
  directory_mapping="{\"Entry\":\"\/$bucket\/$path\",\"Target\":\"\/$bucket\/$path\"}"
  directory_mappings+=("$directory_mapping")
  policy_statements+=("$policy_statement")
done <<< "$LOCATIONS"

# Join the individual policy statements with commas
policy_statements_list=$(IFS=, ; echo "${policy_statements[*]}")
directory_mappings_list=$(IFS=, ; echo "${directory_mappings[*]}")
bucket_arns_list=$(IFS=, ; echo "${bucket_arns[*]}")

list_buckets="{\"Action\":[\"s3:ListBucket\"],\"Effect\":\"Allow\",\"Resource\":[$bucket_arns_list]}"
policy_statements_list="$list_buckets,$policy_statements_list"
# Combine individual policy statements into a single policy
policy="{\"Version\":\"2012-10-17\",\"Statement\":[$policy_statements_list]}"
home_directory_mapping="[$directory_mappings_list]"
echo "Generated Policy:"
echo "$policy"
echo "Generated home directory mapping:"
echo "$home_directory_mapping"

/usr/bin/aws transfer create-user \
--user-name $USER \
--tags "[{\"Key\": \"DeletionDate\",\"Value\": \"$DELETION_D\"}]" \
--role arn:aws:iam::533266989803:role/sftp-role \
--server-id s-138b528d3f954b46b --ssh-public-key-body "$(< $SSH_PATH/$USER.pub)" \
--home-directory-type LOGICAL \
--policy $policy \
--home-directory-mappings $home_directory_mapping --region us-east-1






