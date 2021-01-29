#!/bin/sh

if [ -z "$CONTAINER_ID" ]; then
  echo -e "ERROR: CONTAINER_ID not specified\n"
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
  curl "$WEBHOOK_URL" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --data "$BODY"
}

round() {
  echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
}

while true; do
  if [ "$ENDPOINT_MONITOR" = true ]; then
    RESPONSE=$(curl --head --write-out '%{http_code}' --silent --output /dev/null "$ENDPOINT_URL")
    MESSAGE="🌐 ENDPOINT_STATUS: $RESPONSE\n"
  fi
  if [ "$HW_MONITOR" = true ]; then
    echo $(curl -s --unix-socket /var/run/docker.sock http://localhost/containers/$CONTAINER_ID/stats?stream=false | jq -c '{"ram":{"rate_usage":((.memory_stats.usage - .memory_stats.stats.cache)/.memory_stats.limit*100),"used_memory": ((.memory_stats.usage - .memory_stats.stats.cache)/1048576), "available_memory": (.memory_stats.limit/1048576)}, "cpu":{"rate_usage":((.cpu_stats.cpu_usage.total_usage - .precpu_stats.cpu_usage.total_usage)/(.cpu_stats.system_cpu_usage - .precpu_stats.system_cpu_usage)*.cpu_stats.online_cpus*100),"cpu_delta": (.cpu_stats.cpu_usage.total_usage - .precpu_stats.cpu_usage.total_usage), "system_cpu_delta":(.cpu_stats.system_cpu_usage - .precpu_stats.system_cpu_usage)}}') >/opt/vol/stats.json
    RAM_RATE=$(jq '.ram.rate_usage' < /opt/vol/stats.json)
    CPU_RATE=$(jq '.cpu.rate_usage' < /opt/vol/stats.json)
    if [ "$(echo "$RAM_RATE > $RAM_LIMIT" | bc -l)" ] || [ "$(echo "$CPU_RATE > $CPU_LIMIT" | bc -l)" ]; then
      MESSAGE="$MESSAGE \n📈 RAM: $(round "$RAM_RATE" 2)\n📈 CPU: $(round "$CPU_RATE" 2)\n"
    fi
  fi
  if [ "$WEBHOOK" = true ]; then
    if [ -n "$WEBHOOK_URL" ] && [ -n "$WEBHOOK_TOKEN" ] && [ -n "$WEBHOOK_ORIGIN" ]; then
      sendToWebHook "$MESSAGE"
    else
      echo -e "One of these variables is not correctly initialised: \nWEBHOOK_URL: $WEBHOOK_URL\nWEBHOOK_TOKEN: $WEBHOOK_TOKEN\nWEBHOOK_ORIGIN: $WEBHOOK_ORIGIN\n"
    fi
  fi
  echo -e "$MESSAGE"
  sleep 10
done
