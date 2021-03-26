#!/bin/sh

CHECK_CONTAINER_ID=$(curl -s --unix-socket /var/run/docker.sock http://localhost/containers/$CONTAINER_ID/stats\?stream\=false | jq .message)
if [[ $CHECK_CONTAINER_ID = *"No such container"* ]] || [ -z "$CHECK_CONTAINER_ID" ]; then
  MESSAGE="ERROR: $CHECK_CONTAINER_ID\nCONTAINER_ID invalid or not specified\n"
  if [ "$WEBHOOK" = true ]; then
    if [ -n "$WEBHOOK_URL" ] && [ -n "$WEBHOOK_TOKEN" ] && [ -n "$WEBHOOK_ORIGIN" ]; then
      sendToWebHook "$MESSAGE"
    fi
    echo -e "$MESSAGE"
  fi
  exit 1
fi

sendToWebHook() {
BODY=$(cat <<EOF
{
"recipient_token": "$WEBHOOK_TOKEN",
"text": "$1",
"origin": "$WEBHOOK_ORIGIN"
}
EOF
)
  curl -s "$WEBHOOK_URL" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --data "$BODY"
}

round() {
  echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
}

log() {
  if [ "$WEBHOOK" = true ]; then
    if [ -n "$WEBHOOK_URL" ] && [ -n "$WEBHOOK_TOKEN" ] && [ -n "$WEBHOOK_ORIGIN" ]; then
      sendToWebHook "$MESSAGE"
    else
      echo -e "One of these variables is not correctly initialised: \nWEBHOOK_URL: $WEBHOOK_URL\nWEBHOOK_TOKEN: $WEBHOOK_TOKEN\nWEBHOOK_ORIGIN: $WEBHOOK_ORIGIN\n"
    fi
  fi
  echo -e "$MESSAGE"
}

FAST_INTERVAL_LIMIT=0

while true; do
  MESSAGE=""
  TRIGGER=false
  if [ "$ENDPOINT_MONITOR" = true ]; then
    RESPONSE=$(curl --head --write-out '%{http_code}' --silent --output /dev/null "$ENDPOINT_URL")
    MESSAGE="🌐 ENDPOINT STATUS: $RESPONSE"
    if [ "$RESPONSE" -gt 200 ]; then
      TRIGGER=true
    fi
  fi
  if [ "$HW_MONITOR" = true ]; then
    echo $(curl -s --unix-socket /var/run/docker.sock http://localhost/containers/$CONTAINER_ID/stats?stream=false | jq -c '{"ram":{"rate_usage":((.memory_stats.usage - .memory_stats.stats.cache)/.memory_stats.limit*100),"used_memory": ((.memory_stats.usage - .memory_stats.stats.cache)/1048576), "available_memory": (.memory_stats.limit/1048576)}, "cpu":{"rate_usage":((.cpu_stats.cpu_usage.total_usage - .precpu_stats.cpu_usage.total_usage)/(.cpu_stats.system_cpu_usage - .precpu_stats.system_cpu_usage)*.cpu_stats.online_cpus*100),"cpu_delta": (.cpu_stats.cpu_usage.total_usage - .precpu_stats.cpu_usage.total_usage), "system_cpu_delta":(.cpu_stats.system_cpu_usage - .precpu_stats.system_cpu_usage)}}') >/opt/vol/stats.json
    RAM_RATE=$(jq '.ram.rate_usage' < /opt/vol/stats.json)
    CPU_RATE=$(jq '.cpu.rate_usage' < /opt/vol/stats.json)
    MESSAGE="$MESSAGE \n📈 RAM: $(round "$RAM_RATE" 2)\n📈 CPU: $(round "$CPU_RATE" 2)\n"
    if [ "$(echo "$RAM_RATE > $RAM_LIMIT" | bc -l)" = 1 ] || [ "$(echo "$CPU_RATE > $CPU_LIMIT" | bc -l)" = 1 ]; then
      TRIGGER=true
    fi
  fi
  if [ $TRIGGER = true ]; then
    log
    if [ $FAST_INTERVAL = true ]; then
      FAST_INTERVAL_LIMIT=$((FAST_INTERVAL_LIMIT+1))
    fi
  fi
  if [ $FAST_INTERVAL = false ] || [ $FAST_INTERVAL_LIMIT -gt 10 ]; then
    sleep "$INTERVAL"
    FAST_INTERVAL_LIMIT=0
  elif [ $FAST_INTERVAL = true ]; then
    sleep 60
  fi
done
