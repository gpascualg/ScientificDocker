# Scientific Docker

This repository contains a template that can build and run both tensorflow and caffe by using docker

## Building

* On new machines, first of all install docker if not already installed. Then run `setup/install.sh` to install nvidia-docker.

* To update or create the docker image run `python build.py`:

  * Specify image name by using `--tag=name`

  * Tensorflow can be build by including `--tensorflow` and version might be specified by `--tensorflow-version=r1.8`

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

## Deleting users

The simplest way is to run the following command

```
scripts/delete_user.sh USERNAME
```

Please note that deleting is irreversible, it deletes all information on the user, including SSH keys if any, and stops and deletes the corresponding docker container.
