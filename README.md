# Scientific Docker

This repository contains a template that can build and run both tensorflow and caffe by using docker

## Building

* On new machines, first of all install docker if not already installed. Then run `setup/install.sh` to install nvidia-docker.

* To update or create the docker image run `python build.py`:

  * Specify image name by using `--tag=name`

  * Tensorflow can be build by including `--tensorflow` and version might be specified by `--tensorflow-version=r1.8` (see https://github.com/tensorflow/tensorflow/branches)

  * If you plan on using GPU add `--gpu`

  * SSH support inside docker can be specified with `--ssh`

  * In newer GPUs (Pascal series and above, 10xx series and Titan X) specify `--half-precision` for better performance

A complete build command might look like:

```
python build.py --tensorflow --tensorflow-version=r1.9 --gpu --ssh --half-precision --tag deepstack
```

You can keep multiple versions by specifying a tag like `deepstack:gpu` or even `deepstack:gpu-tf1.8`, etc.

## Creating new users

A new user can be added to the system using the following command

```
scripts/add_user.sh USERNAME --jupyter=PORT --tensorboard=PORT --password=PASSWORD --data=/DATA/PATH --notebooks=/NOTEBOOKS/PATH
```

Additional parameters might be supplied:

* `--ssh=PORT` to indicate SSH support and the port. It will automatically generate a keypair under the folder `ssh_keys` and give you instructions on how to proceed

* `--image=DOCKER_IMAGE` to anchor the user to a specific docker image. If not specified, the user will always run with the latest built image. `DOCKER_IMAGE` might be any valid docker tag, for example `deepstack`, `deepstack:gpu`, `deepstack:gpu-tf1.8`, etc. as long as the corresponding image exists.

As an example, this would create a new user named `bob`, with SSH access on port 2200, jupyter notebooks on port 8889, tensorboard on 6007 and password `123qwe`. Bob would always use the latest built image (uppon container restart), as no `--image` is specified.

```
scripts/add_user.sh bob --jupyter=8889 --tensorboard=6007 --ssh=2200 --password=123qwe --data=/data/bob_only_data --notebooks=/notebooks/research_team
```

## Deleting users

The simplest way is to run the following command

```
scripts/delete_user.sh USERNAME
```

Please note that deleting is irreversible, it deletes all information on the user, including SSH keys if any, and stops and deletes the corresponding docker container.


## Docker container control

Aside from starting containers, you can use user scripts to stop and restart containers. For example, for `bob`'s container created before, you could

* Stop the container `run_files/run_bob.sh stop`

* Restart the container `run_files/run_bob.sh restart`

* And start it, either by `run_files/run_bob.sh` or `run_files/run_bob.sh start`
