FROM alpine:latest

RUN \
  echo "**** install packages ****" && \
    apk update && \
    apk add --no-cache \
      curl jq bc

# copy local files
COPY . /

ENV HW_MONITOR=true \
  ENDPOINT_MONITOR=false \
  WEBHOOK=false \
  RAM_LIMIT=50 \
  CPU_LIMIT=50 \
  INTERVAL=3600

RUN chmod +x entrypoint.sh
RUN mkdir -p /opt/vol

ENTRYPOINT [ "/entrypoint.sh" ]
