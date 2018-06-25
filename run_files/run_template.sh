# RAW_PASS="__RAWPASS__" # << Injected by the script above, uncomment and edit if done manually
SHA_PASS=$(python -c "from notebook.auth import passwd; print(passwd('$RAW_PASS'))" 2>/dev/null)

if [[ $? -ne 0 ]]; then
    SHA_PASS=$(docker run -i continuumio/anaconda3 python -c "from notebook.auth import passwd; print(passwd('$RAW_PASS'))")

    if [[ $? -ne 0 ]]; then
        echo 'Fatal error, could not find anaconda python installed and docker failed'
        exit 1
    fi
fi

RUNPATH=$(realpath $(dirname "$0")/../scripts)
IMAGE_NAME="__IMAGE__"

if [ -z "$IMAGE_NAME" ]
then
    IMAGE_NAME=$(cat $RUNPATH/latest)
fi

$RUNPATH/run_docker.sh --name __NAME__ -s $RUNPATH/ssh_keys/__NAME__.pub -p __JUPYTER__:8888 -p __TENSORBOARD__:6006 -p __SSH__:22 -v __DATA__:/data -v __NOTEBOOKS__:/notebooks -e JUPYTER_PASSWORD='$SHA_PASS' -e FETCH_TF_CONTRIB=1 $IMAGE_NAME
