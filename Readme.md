# TOR payment service

This is a Docker Compose environment for running a Bitpay server as a hidden
service on the TOR network. This setup is intended for educational purposes


## Warning

While running a TOR hidden service can provide an additional layer of anonymity
and security, it is important to note that it is not a foolproof solution. To
maximize the benefits of a TOR hidden service, it is recommended to take
additional precautions, such as:

- Renting a server from a provider that accepts cryptocurrency and does not
  require any personal information for registration.
- Accessing the server and managing the TOR hidden service via the TOR network
  using the TOR Browser or other TOR-enabled tools.

By taking these precautions, you can help ensure that your real identity is not
linked to the TOR hidden service.

Note that no solution is completely foolproof and it is always recommended to
follow best practices for security and privacy when setting up a payment service.

## Architecture

This container setup assumes that Docker will properly configure the network
environment, including:
- Creating a NAT network for the TOR instance, allowing secure and private
  communication with the TOR network.
- Setting up multiple internal networks for the application, improving security
  and reducing the risk of attacks.


```
        internet
           |
          host
           |
          docker
           |- NAT - extern-net
           |            \- tor
           |- BRIDGE - tor-net
           |            |- tor
           |            |- front
           |            |- service-proxy
           |            \- bitcoind
           |- BRIDGE - pay-front-net
           |            |- front
           |            \- pay-server
           \- BRIDGE - pay-net
                        |- pay-nbx-db
                        |- pay-server-db
                        |- pay-nbx
                        |- pay-server
                        |- service-proxy
                        \- bitcoind
```

`extern-net` obviously connects the tor client with the internet. It is the
             only container that is allowed to create network connections to
             the outside.
`tor-net`    connects all services that are able to communicate using the
             socks5 proxy
`pay-front-net`
             connects the bitpay-server with the front-reverse-proxy
`pay-net`    connects the bitpay-server components (databases, application)

## Front

Caddy server that acts as a interface between bitpay-server and the tor hidden
service. Its used to enhance headers and allow initial password protected setup.
The caddy server has no internet connection and does not manage certificates.

## Service Proxy

The services differ in the support of the socks5 proxy, so a http-proxy was
added that can be used by traditional software. This proxy connects the
`pay-net` with the `tor-net` using privoxy in the default configuration. This
will proxy all http/s requests to the socks5 of the tor-service effectively
torifying them. The configuration exception `nbx` is that the local connection
to the bitpay-server component `nbxplorer` - which is also done via http - still
works.

## Bitpay Server

The bitpay-server is a .net application that does not consider itself safe for
not leaking data. That is the reason we configure it in this local-only
environment and keeping the available channels in check.
The bitpay-server runs as root, build by a third party, so the only boundary
is the linux-kernel which may be tricked into reveling its real ip-address.

# Configuration

This docker compose file expects a `.env` file to be available (or its values
set through the environment).
Initially it needs 3 variables: a bcrypted init-password and the latest
versions of the bitpay-server

The init-password avoids that your newly deployed payment-service is asking every
stranger for setting up the admin-account. the example-configuration is
username: `init`, password: `init`. Use a online generator if you want it
different.

copy .env.example to .env

Without any further configuration, the service will start, create a new hidden
service with the (by then outdated) bitpay server version that can only be
configured if you have the init-password at hand. so not very useful.

## Bitpay Server Version

The versions of bitpay-server have to be set manually:
https://hub.docker.com/r/nicolasdorier/nbxplorer/tags
https://hub.docker.com/r/btcpayserver/btcpayserver/tags
to find the latest.

## Tor
If you do not have a secret&public key for a hidden service, just run the tor
container without its dependencies and extract them as base64:
```
docker compose run --rm tor
then in another terminal
docker ps -> identify the tor container-id
docker exec -it tor-payment-service-tor-run-123456789012 /bin/sh
cat /var/lib/tor/hidden_service/hostname
find /var/lib/tor/hidden_service/ -type f -exec echo "echo {}; base64 -w0 {};echo ''" \;|sh
```
set the variables in .env according to the output

Now every time you start the compose setup, tor will serve the same hidden
service. You'll also learn the hostname with this process that you can use in
the tor browser to connect to your instance

## Bitpay Server

Once you navigated to the hidden service and entered the init-password, you
will be prompted to create a admin-account for your bitpay-server. *Do not* use
a real e-mail address, there is no password recovery, emails will not work in
this setup.

## Front

Once the store is setup and you'd like to route users to it, edit the
front/Caddyfile and remove/comment the `import init_auth` from the server-section

# Backup

You may have noticed that lots of configuration details are done in the
bitpay-server app, so they are stored in the postgres database. You may also
notice that the fullnode required for the setup is requesting alot of data.
Something like a terrabyte. So it will take a while until the node is actually
up for serving customers.
This makes it very important for you to backup the state once it has finished
so you can quickly restart without waiting another day,week....

As the user that is allowed to execute docker commands:
```
bash ./backup.sh
```
creates a full backup of the site including the blockchain.
Three files are created: configuration, server and fullnode.
Once the backup has finished, sync the files to your backup-store.

The files are
```
2024-11-25T193346z-bitpay-server.tar.gz
2024-11-25T193346z-config.tar.gz
2024-11-25T193346z-fullnode.tar.gz
```

To restore, unpack with the 'p' flag to restore permissions as well or use the
restore-script
```
bash ./restore.sh prefix
```
where prefix is the common backup-date `2024-11-25T193346z`

This will create a restore/tor-payment-service directory that you can then move
to the common root (using a privileged shell) or to launch the services using
`docker compose up`. but beware! as the configuration (may) contain the secret
for the hidden service, you could end up with a weird state when you do not
shut down the original instance before.

# Updates

You'll need to follow the bitpay-server guidelines to upgrade. Ideally its
updating your .env and `docker compose up -d` but that may not work when there
are database migrations required. Make sure you test the upgrade with a backup.
The other services (tor,caddy) should regulary be restarted. They are
configured to pull and install their latest on every start.

# Coins

The reason for this service is to receive coins. As shop, as crowdfund as
payment button. You may want to integrate some other service into this setup
so a payment invokes a action that is useful for the user.
Test your setup before. Check that your wallet receives funds if you send them.
The usual measures (backup your wallet, generate key offline etc) should be
followed.

# Users

Bitpay-server allows you to collect userdata (eg a email or a shipping address)
which is bad in case it gets hacked/seized. Please make sure that you only
keep the data as long as you need it. Purge the site with its data as soon
as you do no longer require it. Install plugins that help you doing so.

# Legal

Do not use this service for illegal services. Its not proven to sustain
government level penetration. Stay safe!

# Security

This setup is intended for educational purposes only and should not be used for production environments. Always ensure that you follow best practices for security and privacy when setting up a payment service.

# License

This project is licensed under the MIT License - see the LICENSE file for details.

# Support

bc1qdzvaklhwq7u73dxm59vughd8utkkkt6q76z6a3
