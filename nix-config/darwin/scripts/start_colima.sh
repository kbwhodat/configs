#!/bin/bash

export PATH=/run/current-system/sw/bin:$PATH

function shutdown() {
  colima stop
  exit 0
}

trap shutdown SIGTERM
trap shutdown SIGINT

# wait until colima is running
while true; do
  colima status &>/dev/null
  if [[ $? -eq 0 ]]; then
    break
  fi

  colima start
  sleep 5
done

tail -f /dev/null &
wait $!
