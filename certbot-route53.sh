#!/bin/bash

if [ "$DOMAINS" = "" ]; then
  echo "The DOMAINS environment variable is not set."
  exit 1
fi

if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
  echo "The EMAIL is not valid."
  exit 1
fi

if [ -z $CERTBOT_DOMAIN ]; then
  mkdir -p $PWD/letsencrypt

  certbot certonly \
    --non-interactive \
    --manual \
    --manual-auth-hook $PWD/$0 \
    --manual-cleanup-hook $PWD/$0 \
    --preferred-challenge dns \
    --config-dir $PWD/letsencrypt \
    --work-dir $PWD/letsencrypt \
    --logs-dir $PWD/letsencrypt \
    --agree-tos \
    --manual-public-ip-logging-ok \
    --domains "$DOMAINS" \
    --email "$EMAIL"

else
  [[ $CERTBOT_AUTH_OUTPUT ]] && ACTION="DELETE" || ACTION="UPSERT"

  printf -v QUERY 'HostedZones[?ends_with(`%s.`,Name)].Id' $CERTBOT_DOMAIN

  HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query $QUERY --output text)

  if [ -z $HOSTED_ZONE_ID ]; then
    echo "No hosted zone found that matches $CERTBOT_DOMAIN"
    exit 1
  fi

  aws route53 wait resource-record-sets-changed --id $(
    aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --query ChangeInfo.Id --output text \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"$ACTION\",
        \"ResourceRecordSet\": {
          \"Name\": \"_acme-challenge.$CERTBOT_DOMAIN.\",
          \"ResourceRecords\": [{\"Value\": \"\\\"$CERTBOT_VALIDATION\\\"\"}],
          \"Type\": \"TXT\",
          \"TTL\": 30
        }
      }]
    }"
  )
  
  echo 1
fi
