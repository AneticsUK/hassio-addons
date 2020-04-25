#!/bin/sh

KEY=`jq -r .awskey /data/options.json`
SECRET=`jq -r .awssecret /data/options.json`
ZONEID=`jq -r .zone_id /data/options.json`
RECORDSET=`jq -r .record_set /data/options.json`
TYPE=`jq -r .record_type /data/options.json`

aws configure set aws_access_key_id $KEY
aws configure set aws_secret_access_key $SECRET

while [ : ]
do
  TTL=60

  COMMENT="Auto updating @ `date`"

  # Get the external IP address from OpenDNS (more reliable than other providers)
  IP=`dig +short myip.opendns.com @resolver1.opendns.com`


  # Get current dir
  # (from http://stackoverflow.com/a/246128/920350)
  DIR="$(pwd)"
  LOGFILE="$DIR/update-route53.log"
  IPFILE="$DIR/update-route53.ip"

  # Check if the IP has changed
  if [ ! -f "$IPFILE" ]
      then
      touch "$IPFILE"
  fi

  if grep -Fxq "$IP" "$IPFILE"; then
      # code if found
      echo "IP is still $IP. @ `date`"
      #exit 0
  else
      echo "IP has changed to $IP"
      # Fill a temp file with valid JSON
      TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
      cat > ${TMPFILE} << EOF
      {
        "Comment":"$COMMENT",
        "Changes":[
          {
            "Action":"UPSERT",
            "ResourceRecordSet":{
              "ResourceRecords":[
                {
                  "Value":"$IP"
                }
              ],
              "Name":"$RECORDSET",
              "Type":"$TYPE",
              "TTL":$TTL
            }
          }
        ]
      }
EOF

    # Update the Hosted Zone record
    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONEID \
        --change-batch file://"$TMPFILE"
    echo "IP Changed in Route53"

    # Clean up
    rm $TMPFILE

    # All Done - cache the IP address for next time
    echo "$IP" > "$IPFILE"
    echo "IP Updated"
  fi

  sleep 2m
done
