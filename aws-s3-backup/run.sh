#!/bin/sh

KEY=`jq -r .awskey /data/options.json`
SECRET=`jq -r .awssecret /data/options.json`
BUCKET=`jq -r .bucketname /data/options.json`
PTH=`jq -r .path /data/options.json`

aws configure set aws_access_key_id $KEY
aws configure set aws_secret_access_key $SECRET

aws s3 sync --delete --storage-class STANDARD_IA /backup/ s3://$BUCKET/$PTH

echo "Done"
