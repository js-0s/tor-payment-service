#!/usr/bin/env bash

BACKUP_DATE=$1

die() {
    echo $@
    exit 1
}

if [ -z "${BACKUP_DATE}" ]; then
    die "missing backup date"
fi

FULLNODE=${BACKUP_DATE}-fullnode.tar.gz
SERVER=${BACKUP_DATE}-bitpay-server.tar.gz
CONFIG=${BACKUP_DATE}-config.tar.gz

test -f "${FULLNODE}" \
  || die "missing fullnode backup ${FULLNODE}"

test -f "${SERVER}" \
  || die "missing server backup ${SERVER}"

test -f "${CONFIG}" \
  || die "missing config backup ${CONFIG}"

mkdir -p restore/tor-payment-service

docker run --rm -v "./restore/tor-payment-service:/restore" -v "./:/backup" alpine \
  tar xzpf "/backup/${FULLNODE}" \
    --directory=/restore \
    --strip-components=1 \
    || die "failed to restore fullnode"
docker run --rm -v "./restore/tor-payment-service:/restore" -v "./:/backup" alpine \
  tar xzpf "/backup/${SERVER}" \
    --directory=/restore \
    --strip-components=1 \
    || die "failed to restore bitpay-server"
docker run --rm -v "./restore/tor-payment-service:/restore" -v "./:/backup" alpine \
  tar xzpf "/backup/${CONFIG}" \
    --directory=/restore \
    --strip-components=1 \
    || die "failed to restore config"

touch restore/.restored-from-${BACKUP_DATE}
