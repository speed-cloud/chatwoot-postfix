#!/bin/sh
lightblue="$(printf '\033[38;5;147m')"
red="$(printf '\033[91m')"
reset="$(printf '\033[0m')"

error() {
  printf "${reset}‣ ${red}ERROR ${reset} "
  echo -e "$@${reset}"
}

info() {
  printf "${reset}‣ ${lightblue}INFO ${reset} "
  echo -e "$@${reset}"
}

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

info "Making import-mail-to-rails executable."
chmod +x /usr/local/bin/import-mail-to-rails

info "Setting up Postfix requirements."
sed -i "s/{MAILER_INBOUND_EMAIL_DOMAIN}/$MAILER_INBOUND_EMAIL_DOMAIN/" /etc/postfix/{transport,virtual_alias}
postmap /etc/postfix/{transport,virtual_alias}
postconf -M "rails/unix=rails unix - n n - - pipe flags=Xhq user=nobody argv=/usr/local/bin/import-mail-to-rails"

info "Configuring Postfix for Chatwoot."
postconf -e "smtpd_client_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination"
postconf -e "smtpd_sender_restrictions=permit_mynetworks,reject_unauth_destination"
postconf -e "transport_maps=lmdb:/etc/postfix/transport"
postconf -e "virtual_alias_maps=lmdb:/etc/postfix/virtual_alias"

info "Securing Postfix for inbound emails."
postconf -e "smtp_tls_auth_only=yes"
postconf -e "smtp_tls_security_level=may"
postconf -e "smtp_tls_mandatory_protocols=>=TLSv1.2"
postconf -e "smtp_tls_protocols=>=TLSv1.2"

postconf -e "smtpd_tls_dh1024_param_file=/etc/postfix/dh2048.pem"
postconf -e "smtpd_tls_security_level=may"
postconf -e "smtpd_tls_mandatory_protocols=>=TLSv1.2"
postconf -e "smtpd_tls_protocols=>=TLSv1.2"

postconf -e "tls_eecdh_auto_curves=X25519 prime256v1 secp384r1"
postconf -e "tls_medium_cipherlist=ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305"