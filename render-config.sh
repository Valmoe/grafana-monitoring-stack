#!/bin/sh
# Renders alertmanager/config.yml.tmpl → alertmanager/config.yml
# Run this once before 'docker compose up' whenever .env changes
set -a
. ./.env
set +a

sed \
  -e "s|\${SMTP_FROM}|${SMTP_FROM}|g" \
  -e "s|\${SMTP_USERNAME}|${SMTP_USERNAME}|g" \
  -e "s|\${SMTP_PASSWORD}|${SMTP_PASSWORD}|g" \
  -e "s|\${ALERT_EMAIL_TO_CRITICAL}|${ALERT_EMAIL_TO_CRITICAL}|g" \
  -e "s|\${ALERT_EMAIL_TO}|${ALERT_EMAIL_TO}|g" \
  -e "s|\${GF_SERVER_DOMAIN}|${GF_SERVER_DOMAIN}|g" \
  ./alertmanager/config.yml.tmpl > ./alertmanager/config.yml

echo "✓ alertmanager/config.yml rendered"