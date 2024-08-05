#!/bin/sh

REGISTRY_BINARY=/var/opt/registry
DEFAULT_CONFIG_PATH=/etc/distribution/config.yml
REGISTRY_PATH=/var/lib/registry
RUN_GC_PATH=$REGISTRY_PATH/.run_gc
GC_LOG_PATH=$REGISTRY_PATH/gc.log
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

  $REGISTRY_BINARY garbage-collect $GC_ARGS 2>&1 | tee -a $GC_LOG_PATH
  rm -f "$RUN_GC_PATH"
}

if [ "$1" == "garbage-collect" ]; then
  shift
  
  CONFIG="$1"
  echo "queueing GC..."
  touch $GC_LOG_PATH
  if [ "${CONFIG:0:1}" == "-" ]; then
    echo "$DEFAULT_CONFIG_PATH" "$@" > $RUN_GC_PATH
  else
    echo "$@" > $RUN_GC_PATH
  fi
  
  if [ ! -f "$PID_FILE" ]; then
    return 0
  fi
  
  PID=$(cat $PID_FILE)
  echo "stopping registry (PID: $PID)"
  exec kill -TERM $PID
elif [ "$1" == "serve" ]; then
  run_gc "$@"
  echo $$ > $PID_FILE
fi

exec $REGISTRY_BINARY "$@"
