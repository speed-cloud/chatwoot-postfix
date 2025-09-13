#!/bin/sh
set -euo pipefail

LIGHTBLUE="$(printf '\033[38;5;147m')"
RED="$(printf '\033[91m')"
RESET="$(printf '\033[0m')"

error() { printf "‣ ${RED}ERROR${RESET} %b\n" "$@"; }
info() { printf "‣ ${LIGHTBLUE}INFO${RESET} %b\n" "$@"; }

# --------------------------------------------------

if [ -z "$MAILER_INBOUND_EMAIL_DOMAIN" ]; then
  error "Please define the MAILER_INBOUND_EMAIL_DOMAIN environment variable before starting this container."
  exit 1
fi

if [ -z "$RAILS_HOST" ]; then
  error "Please define the RAILS_HOST environment variable before starting this container."
  exit 1
fi

if [ -z "$RAILS_INBOUND_EMAIL_PASSWORD" ]; then
  error "Please define the RAILS_INBOUND_EMAIL_PASSWORD environment variable before starting this container."
  exit 1
fi

# --------------------------------------------------

info "Setting up import-mail-to-rails requirements."

chmod +x /usr/local/bin/import-mail-to-rails
useradd -m rails

cat > /etc/postfix/import-mail-to-rails.cf <<EOF
RAILS_HOST="${RAILS_HOST}"
RAILS_INBOUND_EMAIL_PASSWORD="${RAILS_INBOUND_EMAIL_PASSWORD}"
EOF

install -m 400 -o rails -g rails /etc/postfix/import-mail-to-rails.cf /etc/postfix/import-mail-to-rails.cf

# --------------------------------------------------

info "Setting up Postfix requirements."

echo "${MAILER_INBOUND_EMAIL_DOMAIN} rails:" > /etc/postfix/transport
postmap /etc/postfix/transport
postconf -M "rails/unix=rails unix - n n - - pipe flags=Xhq user=rails argv=/usr/local/bin/import-mail-to-rails"

# --------------------------------------------------

info "Configuring Postfix for Chatwoot."

postconf -e "smtpd_client_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination" \
  "smtpd_sender_restrictions=permit_mynetworks,reject_unauth_destination" \
  "transport_maps=lmdb:/etc/postfix/transport"

# --------------------------------------------------

info "Securing Postfix for inbound emails."
postconf -e "smtp_tls_security_level=may" \
  "smtp_tls_mandatory_protocols=>=TLSv1.2" \
  "smtp_tls_protocols=>=TLSv1.2" \
  "smtpd_tls_auth_only=yes" \
  "smtpd_tls_dh1024_param_file=/etc/postfix/dh2048.pem" \
  "smtpd_tls_security_level=may" \
  "smtpd_tls_mandatory_protocols=>=TLSv1.2" \
  "smtpd_tls_protocols=>=TLSv1.2" \
  "tls_eecdh_auto_curves=X25519 prime256v1 secp384r1" \
  "tls_medium_cipherlist=ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305"