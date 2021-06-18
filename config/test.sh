#!/bin/bash
pause=1
max_wait=10
wait=0
max_cpu=0.7
while (( $pause == 1 && $wait < $max_wait )); do
  # Get CPU for last minute
  val=$(curl -g -f 'http://localhost:9090/api/v1/query?query=instance:node_cpu_utilisation:rate1m{instance="${MY_NODE_IP}:9100"}' \
  | jq '.data.result[0].value[1]' |sed 's/"//g')
  echo "CPU usage of node $MY_NODE_NAME - $MY_NODE_IP is $val"
  if (( $(echo "$max_cpu > $val"|bc) ));
  then
    pause=0
  else
    # Wait til next set of stats
    sleep 61
    wait=$((wait+1))
  fi

done
