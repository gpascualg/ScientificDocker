#!/bin/bash

RUNPATH=$(realpath $(dirname "$0")/..)
. $RUNPATH/scripts/utils.sh

# handle non-option arguments
if [[ $# -ne 1 ]]; then
    echo "$0: A name is required."
    exit 1
fi

USERNAME=$1
USERFILE=$RUNPATH/run_files/run_$USERNAME.sh
if [ ! -f $USERFILE ]
then
    echo "This user does not exist"
    exit 2
fi

if ! docker stats --no-stream &>/dev/null
then
    echo "Could not run docker, please use sudo"
    exit 3
fi

negconfirm && exit 4

rm -f $USERFILE
rm -f $RUNPATH/ssh_keys/$USERNAME
rm -f $RUNPATH/ssh_keys/$USERNAME.pub

if docker stop $USERNAME &>/dev/null
then
    echo "Docker stopped"
else
    echo "Could not stop docker, maybe it was not running at all?"
fi

if docker rm $USERNAME &>/dev/null
then
    echo "Docker removed"
else
    echo "Could not remove docker, maybe it was never started?"
fi

echo "Done"
