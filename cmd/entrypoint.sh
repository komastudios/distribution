#!/bin/sh

DEFAULT_CONFIG_PATH=/etc/distribution/config.yml
RUN_GC_PATH=/var/lib/registry/.run_gc
PID_FILE=/var/run/registry.pid

run_gc() {
  if [ ! -f "$RUN_GC_PATH" ]; then
    echo "skipping GC"
    return
  fi

  echo "running GC..."
  GC_ARGS=$(cat $RUN_GC_PATH)
  if [ -z "$GC_ARGS" ]; then
    shift
    GC_ARGS="$@"
  fi

  rm -f "$RUN_GC_PATH"
  registry garbage-collect "$GC_ARGS"
}

if [ "$1" == "garbage-collect" ]; then
  shift
  
  CONFIG="$1"
  echo "queueing GC..."
  if [ "${CONFIG:0:1}" == "-" ]; then
    echo "$DEFAULT_CONFIG_PATH" "$@" > $RUN_GC_PATH
  else
    echo "$@" > $RUN_GC_PATH
  fi
  
  if [ ! -f "$PID_FILE" ]; then
    return 0
  fi
  
  $PID=$(cat $PID_FILE)
  echo "stopping registry (PID: $PID)"
  exec kill -TERM $PID
elif [ "$1" == "serve" ]; then
  run_gc "$@"
  echo $$ > $PID_FILE
fi

exec registry "$@"
