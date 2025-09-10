# chatwoot-postfix
A simple and "GitOps-y" way to use Postfix on a Docker installation of Chatwoot. <br />
Based on the [`boky/postfix`](https://github.com/bokysan/docker-postfix) Docker image.

## How to set up `chatwoot-postfix`?
You will need to add the following code into your `compose.yaml`, in the `services` section.
```yaml
postfix:
  image: ghcr.io/speed-cloud/chatwoot-postfix
  env_file: .env
  ports:
    - target: 587
      published: 587 # You can switch this port if you are using an incoming SMTP relay.
      protocol: tcp
      mode: host
  volumes:
    - ./dkim:/etc/opendkim/keys:ro # This is required to set up DKIM.
```

Now, time to check if you set the following environment variables.
- [ ] `OPENDKIM_KeyFile` *(required for email deliverability)*
- [ ] `OPENDKIM_Selector` *(needed to sign the outgoing emails)*
- [ ] `MAILER_INBOUND_EMAIL_DOMAIN` *(fetched from the `.env` file, if shared with Chatwoot)*
- [ ] `RAILS_HOST` *(needed to forward emails to Rails)*
- [ ] `RAILS_INBOUND_EMAIL_PASSWORD` *(fetched from the `.env` file, if shared with Chatwoot)*

This is all.

*chatwoot-postifx is not an official project of Chatwoot, Inc. nor endorsed by them.*
*All support will be made by Groupe Speed Cloud, a french nonprofit.*