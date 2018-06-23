# Scientific Docker

This repository contains a template that can build and run both tensorflow and caffe by using docker

## Building

* First of all, install docker if not already installed.

* Run `setup/install.sh` to install nvidia-docker

* Run `python build.py`:

  * Specify image name by using `--tag=name`

  * Tensorflow can be build by including `--tensorflow` and version might be specified by `--tensorflow-version=r1.8`

  * If you plan on using GPU add `--gpu`

  * SSH support inside docker can be specified with `--ssh`

  * In newer GPUs (Pascal and above) specify `--half-precision` for extended and better support

A complete build command might look like:

```
python build.py --tensorflow --tensorflow-version=r1.8 --gpu --ssh --half-precision --tag deepstack:gpu-tensorflow1.8
```

## Creating new users

A new user can be added to the system using the following command


