#!/usr/bin/env bash

BACKUP_DATE=$(date -u +"%Y-%m-%dT%H%M%Sz"|sed 's|[ :]||g')

BACKUP_CONFIG=YES
BACKUP_FULLNODE=YES
BACKUP_SERVER=YES

die() {
    echo $@
    exit 1
}


if [ -n "${BACKUP_CONFIG}" ]; then
  docker run --rm -v "./:/backup-${BACKUP_DATE}" alpine \
  tar czpf "/backup-${BACKUP_DATE}/${BACKUP_DATE}-config.tar.gz" \
  "/backup-${BACKUP_DATE}/.env" \
  "/backup-${BACKUP_DATE}/front/Caddyfile" \
  "/backup-${BACKUP_DATE}/docker-compose.yml" \
  || die "failed to backup configuration"
fi

if [ -n "${BACKUP_FULLNODE}" ]; then
  docker run --rm -v "./:/backup-${BACKUP_DATE}" alpine \
  tar czpf "/backup-${BACKUP_DATE}/${BACKUP_DATE}-fullnode.tar.gz" \
  "/backup-${BACKUP_DATE}/local_data/pay/bitcoin_datadir" \
  || die "failed to backup full node"
fi

if [ -n "${BACKUP_SERVER}" ]; then
  docker run --rm -v "./:/backup-${BACKUP_DATE}" alpine \
  tar czpf "/backup-${BACKUP_DATE}/${BACKUP_DATE}-bitpay-server.tar.gz" \
  "/backup-${BACKUP_DATE}/local_data/pay/bitcoin_wallet_datadir" \
  "/backup-${BACKUP_DATE}/local_data/pay/data" \
  "/backup-${BACKUP_DATE}/local_data/pay/db-nbx" \
  "/backup-${BACKUP_DATE}/local_data/pay/db-server" \
  "/backup-${BACKUP_DATE}/local_data/pay/nbx-data" \
  "/backup-${BACKUP_DATE}/local_data/pay/plugins" \
  || die "failed to backup bitpay-server"
fi
