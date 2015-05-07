# mesos

This is used to build mesos docker image, the Consul is packaged into this image as the Service Discovery tools.

## Build image

```
sudo docker build -t mesos ./
```

## Run docker

I would suggest to run this docker container via the scprit [docker-mesos](https://github.com/nalandas/operation/blob/master/scripts/docker-mesos "docker-mesos") in **operation** repository which can give your container real IP address and will be accessable out of the container host.
