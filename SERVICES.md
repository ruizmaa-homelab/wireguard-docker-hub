# Home server services

This document details the deployment of dockerized self-hosted services running on your local Home Server.

## Prerequisites

### Docker & Docker compose installed

Follow the [official documentation](https://docs.docker.com/engine/install/) to install it.

## Services

The services are defined in `services/docker-compose.yml`. Copy the services you need to your main `docker-compose.yml` or run them directly from that directory.

Start the services:

```bash
docker compose up -d
```

Check the status:

```bash
docker compose ps
```

---

### [Pi-hole](https://hub.docker.com/r/pihole/pihole)

A network-wide ad blocking software acting as a DNS sinkhole.

#### Configuration

- Web interface: http://<SERVER_IP>:8080/admin

##### Change the password

You can set your own password by editing the docker compose, just uncomment the `WEBPASSWORD` environment variable and write your own password.

If you don't specify your password, it will be generated randomly, the easiest way to change it is using this command:

```bash
docker exec -it pihole pihole setpassword
```

##### Settings

Go to `http://<SERVER_IP>:8080/admin` and log in with your password.

Configure your **Upstream DNS Servers** and **Interface Settings** (allow traffic from the Docker container and your local net):

1. Go to `Settings > DNS`
2. Go to `Upstream DNS Servers`, select your preferred provider
3. Go to `Interface settings`, select Potentially dangerous options > ` Permit all origins`
4. Save

Update **Blocklists** (Gravity) to ensure Pi-hole knows which ads to block:

1. Go to `Tools > Update Gravity`
2. Click the `Update` button

>You can also use this command:
>
>`docker exec -it pihole pihole -g`

#### Check if it's working

Check if unwanted traffic is blocked:

```bash
nslookup flurry.com
```

You should read something like this:

```text
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	flurry.com
Address: 0.0.0.0
Name:	flurry.com
Address: ::

```

Check if desired traffic is allowed:

```bash
nslookup google.com
```

This should show something like this:

```text
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.184.174
Name:	google.com
Address: 2a00:1450:4003:803::200e
```
