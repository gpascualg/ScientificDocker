#!/bin/bash

# Make sure the user can run docker
if ! docker stats --no-stream &>/dev/null
then
    echo "User does not have permission to run docker, please use sudo"
    exit 3
fi

# Options are start|restart|stop
MODE="start"
if [[ $# -ge 1 ]]
then
    if [ "$1" == "start" ] || [ "$1" == "restart" ] || [ "$1" == "stop" ]
    then
        MODE=$1
    else
        echo "Options are start | restart | stop"
        exit 1
    fi
fi

# Start mode
if [ "$MODE" == "start" ]
then
    if [ ! -z $(docker ps --filter="name=__NAME__" -q) ]
    then
        echo "This user is already running, either restart or stop it"
        echo -e "\t$0 restart | stop"
        exit 1
    fi

    RAW_PASS="__RAWPASS__" # If manually editing, change this
    SHA_PASS=$(python -c "from notebook.auth import passwd; print(passwd('$RAW_PASS'))" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        SHA_PASS=$(docker run -i continuumio/anaconda3 python -c "from notebook.auth import passwd; print(passwd('$RAW_PASS'))")

        if [[ $? -ne 0 ]]; then
            echo 'Fatal error, could not find anaconda python installed and docker failed'
            exit 1
        fi
    fi

    RUNPATH=$(realpath $(dirname "$0")/..)
    IMAGE_NAME="__IMAGE__"

    if [ -z "$IMAGE_NAME" ]
    then
        IMAGE_NAME=$(cat $RUNPATH/latest)
    fi

    $RUNPATH/scripts/run_docker.sh --name __NAME__ -s $RUNPATH/ssh_keys/__NAME__.pub -p __JUPYTER__:8888 -p __TENSORBOARD__:6006 -p __SSH__:22 -v __DATA__:/data -v __NOTEBOOKS__:/notebooks -e JUPYTER_PASSWORD="$SHA_PASS" -e FETCH_TF_CONTRIB=1 $IMAGE_NAME

# Either restart or stop
else
    if [ -z $(docker ps --filter="name=__NAME__" -q) ]
    then
        echo "Could not find the user's container, start it with"
        echo -e "\t$0 start"
        exit 1
    fi

    # Stop and remove container
    docker stop __NAME__ &>/dev/null
    docker rm __NAME__ &>/dev/null

    if [ "$MODE" == "restart" ]
    then
        # Re-run this script with start mode
        $0 start
    fi

fi
