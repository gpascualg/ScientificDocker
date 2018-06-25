#!/bin/bash

RUNPATH=$(realpath $(dirname "$0")/..)

. /lib/lsb/init-functions

MODE="start"
if [[ $# -ge 1 ]]; then
    if [ "$1" == "start" ] || [ "$1" == "restart" ] || [ "$1" == "stop" ]
    then
        MODE=$1
    else
        echo "Options are start | restart | stop"
        exit 1
    fi
fi

log_daemon_msg "Starting with MODE=$MODE" "deepstack-control" || true; echo

for f in $(ls $RUNPATH/run_files/)
do
	if [ $f != "run_template.sh" ]
	then
		log_daemon_msg "$MODE [$f]" "deepstack-control" || true; echo
	        $RUNPATH/run_files/$f $MODE
	fi
done
