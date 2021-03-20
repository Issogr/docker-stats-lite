# docker-stats-lite

## Variables

You can specify the following variables:
* `CONTAINER_ID=<id>` **required**
* `HW_MONITOR=<enable hw monitoring>` (true|false) **default: true**
* `RAM_LIMIT=` (number) **default: 50**
* `CPU_LIMIT=` (number) **default: 50**
* `ENDPOINT_MONITOR=<enable endpoint monitoring>` (true|false) **default: false**
* `ENDPOINT_URL=` (https://...)
* `WEBHOOK=<enable sending messages to webhooks>` (true|false) **default: false**
* `WEBHOOK_TOKEN=`
* `WEBHOOK_URL=`
* `WEBHOOK_ORIGIN=<the name displayed on the wehook as the source of the message>`
* `INTERVAL=<the wait in seconds between logs, to avoid spam>` (number) **default:1800**

## Required

The resource must be mounted  
```console
/var/run/docker.sock:/var/run/docker.sock
```

## Reference
[Docker API](https://docs.docker.com/engine/api/v1.41/#operation/ContainerStats)