#!/bin/sh

round() {
  echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
}

while true; do
  echo $(curl --unix-socket /var/run/docker.sock http://localhost/containers/$CONTAINER_ID/stats?stream=false | jq -c '{"ram":{"rate_usage":((.memory_stats.usage - .memory_stats.stats.cache)/.memory_stats.limit*100),"used_memory": ((.memory_stats.usage - .memory_stats.stats.cache)/1048576), "available_memory": (.memory_stats.limit/1048576)}, "cpu":{"rate_usage":((.cpu_stats.cpu_usage.total_usage - .precpu_stats.cpu_usage.total_usage)/(.cpu_stats.system_cpu_usage - .precpu_stats.system_cpu_usage)*.cpu_stats.online_cpus*100),"cpu_delta": (.cpu_stats.cpu_usage.total_usage - .precpu_stats.cpu_usage.total_usage), "system_cpu_delta":(.cpu_stats.system_cpu_usage - .precpu_stats.system_cpu_usage)}}') >/opt/vol/stats.json
  RAM_RATE=$(cat /opt/vol/stats.json | jq '.ram.rate_usage')
  CPU_RATE=$(cat /opt/vol/stats.json | jq '.cpu.rate_usage')
  if [[ $(echo "$RAM_RATE > $RAM_LIMIT" | bc -l) || $(echo "$CPU_RATE > $CPU_LIMIT" | bc -l) ]]; then
    echo -e "\n📈 RAM: $(round $RAM_RATE 2)"
    echo -e "📈 CPU: $(round $CPU_RATE 2)\n"
  fi
  sleep 5
done
