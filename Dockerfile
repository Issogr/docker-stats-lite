FROM alpine:latest

RUN \
  echo "**** install packages ****" && \
    apk update && \
    apk add --no-cache \
      curl

# copy local files
COPY . /

RUN chmod +x entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
