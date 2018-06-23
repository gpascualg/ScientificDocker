#!/bin/bash

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I'm sorry, `getopt --test` failed in this environment."
    exit 1
fi

OPTIONS=s:v:p:e:
LONGOPTIONS=ssh-key:,volume:,port:,env:,name:

# -temporarily store output to be able to check for errors
# -activate advanced mode getopt quoting e.g. via “--options”
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# use eval with "$PARSED" to properly handle the quoting
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -p|--password)
            p="$2"
            shift 2
            ;;
        -j|--jupyter)
            j="$2"
            shift 2
            ;;
        -s|--ssh)
            s="$2"
            shift 2
            ;;
        -b|--tensorboard)
            t="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# handle non-option arguments
if [[ $# -ne 1 ]]; then
    echo "$0: A name is required."
    exit 4
fi

RUNPATH=$(realpath $(dirname "$0")/..)

if [ -f $RUNPATH/run_files/run_$0 ]
then
    echo "This user already exists"
    exit 5
fi
