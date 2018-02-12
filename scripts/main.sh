#!/bin/bash

archive() {
  CERTNAME="$1"

  CERTBLOBDIR="../.certblobs"
  mkdir -p "$CERTBLOBDIR"

  LIVEDIR="../.certbot/$CERTNAME/config/live"
  DIR="$LIVEDIR/$(ls "$LIVEDIR" | head -1)"

  TMPDIR="$(tempfile)"
  rm "$TMPDIR"
  mkdir -p "$TMPDIR"
  cp "$DIR/cert.pem" "$TMPDIR/cert.pem"
  cp "$DIR/chain.pem" "$TMPDIR/chain.pem"
  cp "$DIR/fullchain.pem" "$TMPDIR/fullchain.pem"
  cp "$DIR/privkey.pem" "$TMPDIR/privkey.pem"
  touch -a -m -t 197001010000.00 $TMPDIR/*
  chmod 400 $TMPDIR/*
  chown 1000:1000 $TMPDIR/*

  pushd "$TMPDIR" >/dev/null
  TMPARCHIVE="$(tempfile)"
  tar cjf "$TMPARCHIVE" *
  popd >/dev/null

  if [ ! -e "$CERTBLOBDIR/$CERTNAME.tar.bz2" ]; then
    mv "$TMPARCHIVE" "$CERTBLOBDIR/$CERTNAME.tar.bz2"
    encrypt "$CERTNAME"
  else
    CHECKSUM0="$(md5sum "$TMPARCHIVE" | sed 's/ .*//')"
    CHECKSUM1="$(md5sum "$CERTBLOBDIR/$CERTNAME.tar.bz2" | sed 's/ .*//')"
    echo "$CHECKSUM0 $CHECKSUM1"
    if [ "$CHECKSUM0" != "$CHECKSUM1" ]; then
      cp "$TMPARCHIVE" "$CERTBLOBDIR/$CERTNAME.tar.bz2"
      encrypt "$CERTNAME"
    fi
  fi
  if [ ! -e "$CERTBLOBDIR/$CERTNAME.tar.bz2.gpg" ]; then
    encrypt "$CERTNAME"
  fi
  rm -Rf "$TMPDIR"
}

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

encrypt() {
  CERTNAME="$1"

  CERTBLOBDIR="../.certblobs"
  ENCPASS="$(encryptionpassphrase "$CERTNAME")"
  if [ "$ENCPASS" != "" ]; then
    echo "$ENCPASS" | gpg --passphrase-fd 0 --batch --yes \
      --output "$CERTBLOBDIR/$CERTNAME.tar.bz2.gpg" \
      --symmetric "$CERTBLOBDIR/$CERTNAME.tar.bz2"
  fi

}

encryptionpassphrase() {
  CERTNAME="$1"
  certconfig "$CERTNAME" | jq -r '.encryption_passphrase'
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
  archive "$CERTNAME"
done

popd >/dev/null
