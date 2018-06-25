#!/bin/bash

RUNPATH=$(realpath $(dirname "$0")/..)
. $RUNPATH/scripts/utils.sh
check_getopt

OPTIONS=i:d:n:p:j:s:b:
LONGOPTIONS=image:,data:,notebooks:,password:,jupyter:,ssh:,tensorboard:,name:

parse_getopt $@
eval set -- "$PARSED"

# Some defaults for parameters
j="8888"
s="2200"
b="6006"
ssh="false"

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
            ssh="true"
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

USERNAME=$1
USERFILE=$RUNPATH/run_files/run_$USERNAME.sh
SERVER_IP=$(ip route get 1 | awk '{print $NF;exit}')

if [ -f $USERFILE ]
then
    echo "This user already exists"
    echo "If you want to remove it please run"
    echo "$RUNPATH/scripts/delete_user.sh $USERNAME"
    exit 5
fi

if [ -z "$i" ]
then
    if [ -f $RUNPATH/latest ]
    then
        echo "This user will always run with the latest build, take that into account"
    else
        echo "Specify docker image name via --image=name"
        exit 5
    fi
fi

if [ -z "$d" ]
then
    echo "Specify data directory via --data=/some/path"
    exit 6
else
    d=$(realpath $d)
fi

if [ -z "$n" ]
then
    echo "Specify notebooks directory via --notebooks=/some/path"
    exit 7
else
    n=$(realpath $n)
fi

echo "Building user <$USERNAME> with the following options:"
echo -e "\tJupyter notebooks port: $j"
echo -e "\tTensorboard port: $b"
echo -e "\tUser password: $p"
echo -e "\tSSH support: $ssh"
if [ "$ssh" == "true" ]; then
    echo -e "\t\tAt port: $s"
fi
echo -e "\tData path: $d"
echo -e "\tNotebooks path: $n"

negconfirm && exit 1

# Generate SSH key-pair if needed
if [ "$ssh" == "true" ]
then
    ssh-keygen -b 2048 -t rsa -f $RUNPATH/ssh_keys/$USERNAME -q -N "$p"
    echo ""
    echo "Please send $RUNPATH/ssh_keys/$USERNAME to the end-user, it is his SSH login method"
    echo "Instructions to login are:"
    echo -e "\t1) First time only, run"
    echo -e "\t\tchmod 600 $USERNAME"
    echo -e "\t2) Anytime after 1)"
    echo -e "\t\tssh $SERVER_IP:$s -i $USERNAME"
    if [ ! -z "$p" ]; then
        echo -e "\tSame password as specified in this command"
    fi
    echo "Where $USERNAME is the file above"
fi

TEMPLATE=$RUNPATH/run_files/run_template.sh
TEMPLATE_CONTENTS=$(cat $TEMPLATE)
echo -e "RAW_PASS=\"$p\"\n$TEMPLATE_CONTENTS" > $USERFILE

sed -i "s/__NAME__/$USERNAME/g" $USERFILE
sed -i "s/__JUPYTER__/$j/g" $USERFILE
sed -i "s/__TENSORBOARD__/$b/g" $USERFILE
sed -i "s/__SSH__/$s/g" $USERFILE
sed -i "s/__IMAGE__/$i/g" $USERFILE
sed -i "s#__DATA__#$d#g" $USERFILE
sed -i "s#__NOTEBOOKS__#$n#g" $USERFILE

chmod +x $USERFILE
echo ""

if ! docker stats --no-stream &>/dev/null
then
    echo "User has no permission to start docker containers, please manually run"
    echo -e "\tsudo $USERFILE"
    echo "Once done, notebooks server is available at http://$SERVER_IP:$j"
    exit 3
fi

echo "User created, starting container now"
$USERFILE
echo "Done, instruct user to go to http://$SERVER_IP:$j"
