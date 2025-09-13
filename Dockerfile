FROM boky/postfix:4.4.0-alpine

LABEL maintainer="Groupe Speed Cloud <contact@groupe-speed.cloud>"
LABEL org.opencontainers.image.source="https://github.com/speed-cloud/chatwoot-postfix"
LABEL org.opencontainers.image.description="A simple and \"GitOps-y\" way to use Postfix on a Docker installation of Chatwoot."

COPY bin/import-mail-to-rails /usr/local/bin/
COPY bin/setup.sh /docker-init.db/
COPY conf/dh2048.pem /etc/postfix/

ENV ALLOW_EMPTY_SENDER_DOMAINS=true
ENV OPENDKIM_Domain=*
ENV OPENDKIM_KeyTable=
ENV OPENDKIM_SigningTable=