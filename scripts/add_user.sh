#!/bin/bash

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I'm sorry, `getopt --test` failed in this environment."
    exit 1
fi

OPTIONS=i:d:n:p:j:s:b:
LONGOPTIONS=image:,data:,notebooks:,password:,jupyter:,ssh:,tensorboard:,name:

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

# Some defaults for parameters
j="8888"
s="2200"
b="6006"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -i|--image)
            i="$2"
            shift 2
            ;;
        -d|--data)
            d="$2"
            shift 2
            ;;
        -n|--notebooks)
            n="$2"
            shift 2
            ;;
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
            b="$2"
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

if [ -z "$i" ]
then
    echo "Specify docker image name via --image=name"
    exit 5
fi

if [ -z "$d" ]
then
    echo "Specify data directory via --data=/some/path"
    exit 6
fi

if [ -z "$n" ]
then
    echo "Specify notebooks directory via --notebooks=/some/path"
    exit 7
fi

RUNPATH=$(realpath $(dirname "$0")/..)
USERFILE=$RUNPATH/run_files/run_$1.sh
if [ -f $USERFILE ]
then
    echo "This user already exists"
    echo "If you want to remove it please run"
    echo "rm $USERFILE && docker stop $1 && docker rm $1"
    exit 5
fi

TEMPLATE=$RUNPATH/run_files/run_template.sh
TEMPLATE_CONTENTS=$(cat $TEMPLATE)
echo -e "RAW_PASS=\"$p\"\n$TEMPLATE_CONTENTS" > $USERFILE

sed -i "s/__NAME__/$1/g" $USERFILE
sed -i "s/__JUPYTER__/$j/g" $USERFILE
sed -i "s/__TENSORBOARD__/$b/g" $USERFILE
sed -i "s/__SSH__/$s/g" $USERFILE
sed -i "s/__IMAGE__/$i/g" $USERFILE
sed -i "s#__DATA__#$d#g" $USERFILE
sed -i "s#__NOTEBOOKS__#$n#g" $USERFILE
