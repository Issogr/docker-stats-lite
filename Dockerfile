FROM alpine:latest

RUN \
  echo "**** install packages ****" && \
    apk update && \
    apk add --no-cache \
      curl jq bc

# copy local files
COPY . /

RUN chmod +x entrypoint.sh
RUN mkdir -p /opt/vol

ENTRYPOINT [ "/entrypoint.sh" ]
