#!/bin/bash
cd $(dirname $0)
run() {
  script=${1}
  shift
  nohup node ${script}.js "$@" &
}

BT_CONFIG_DIR=/etc/blocktogether/config

run actions > /etc/blocktogether/logs/actions.log 2<&1
run update-users > /etc/blocktogether/logs/update-users.log 2<&1
run update-blocks > /etc/blocktogether/logs/update-blocks.log 2<&1
run deleter > /etc/blocktogether/logs/deleter.log 2<&1
run blocktogether --port 3000 | tee /etc/blocktogether/logs/blocktogether.log 2<&1
