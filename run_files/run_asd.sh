RAW_PASS="123wqe"
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
$RUNPATH/run_docker.sh --name asd -s ../ssh_keys/asd.pub -p 1:8888 -p 3:6006 -p 2:22 -v /ho/da:/data -v /da/di:/notebooks -e JUPYTER_PASSWORD='$SHA_PASS' -e FETCH_TF_CONTRIB=1 deepstack
