# docker-stats-lite

## Usage

### Variables

You can specify the following variables:
* `CONTAINER_ID=<container id>` (f61e66b1ceca)
* `HW_MONITOR=<enable hw monitoring>` (true|false) default: true
* `ENDPOINT_MONITOR=<enable site endpoint monitoring>` (true|false) default: false
* `WEBHOOK=<enable sending messages to webhooks>` (true|false) default: false
* `RAM_LIMIT=` (number) default: 50
* `CPU_LIMIT=` (number) default: 50
* `ENDPOINT_URL=` (https://...)
* `WEBHOOK_TOKEN=`
* `WEBHOOK_URL=`
* `WEBHOOK_ORIGIN=<the name displayed on the wehook as the source of the message>`

### Required

The resource must be mounted  
```console
/var/run/docker.sock:/var/run/docker.sock
```

## Reference
[Docker API](https://docs.docker.com/engine/api/v1.41/#operation/ContainerStats)