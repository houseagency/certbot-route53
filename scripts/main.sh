#!/bin/bash

certconfig() {
  CERTNAME="$1"
  config | jq -r ".[\"$CERTNAME\"]"
}

certnames() {
  config | jq -r '. | keys | .[] '
}

config() {
  cat ../config.json
}

domains() {
  CERTNAME="$1"
  certconfig "$CERTNAME" | jq -r '.domains[]'
}

email() {
  CERTNAME="$1"
  certconfig "$CERTNAME" | jq -r '.email'
}

letsencrypt() {
  CERTNAME="$1"

  DOMAINS=""
  for DOMAIN in $(domains "$CERTNAME"); do
    if [ "$DOMAINS" = "" ]; then
      DOMAINS="$DOMAIN"
    else
      DOMAINS="$DOMAINS,$DOMAIN"
    fi
  done

  CERTBOT_BASEDIR="../.certbot/$CERTNAME"
  CONFIGDIR="$CERTBOT_BASEDIR/config"
  WORKDIR="$CERTBOT_BASEDIR/workdir"
  LOGSDIR="$CERTBOT_BASEDIR/logs"
  mkdir -p "$CONFIGDIR"
  mkdir -p "$WORKDIR"
  mkdir -p "$LOGSDIR"

  AWS_ACCESS_KEY_ID="$(route53keyid "$CERTNAME")" \
    AWS_SECRET_ACCESS_KEY="$(route53secretkey "$CERTNAME")" \
    certbot certonly \
      --non-interactive \
      --staging \
      --manual \
      --manual-auth-hook ./route53.sh \
      --manual-cleanup-hook ./route53.sh \
      --preferred-challenge dns \
      --config-dir "$CONFIGDIR" \
      --work-dir "$WORKDIR" \
      --logs-dir "$LOGSDIR" \
      --agree-tos \
      --manual-public-ip-logging-ok \
      --domains $DOMAINS \
      --email "$(email "$CERTNAME")"
}

route53keyid() {
  CERTNAME="$1"
  certconfig "$CERTNAME" | jq -r '.route53_credentials.aws_key_id'
}

route53secretkey() {
  CERTNAME="$1"
  certconfig "$CERTNAME" | jq -r '.route53_credentials.aws_secret_key'
}

IFS=$'\n'

pushd "$(dirname $0)" >/dev/null

for CERTNAME in $(certnames); do
  letsencrypt "$CERTNAME"
done

popd >/dev/null
