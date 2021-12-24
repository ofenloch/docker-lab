# Some Experiments with Docker

## Build the Image and run a Container

To build the image described by **Dockerfile** run

`docker build -t docker-lab:0.0.1 .`


To test / use the image (i.e. run a container) do something like this

`docker run --rm -it -v $(pwd):/workspaces docker-lab:0.0.1 "ls -hal /workspaces"`


## Example Use Case

This project contains a copy of of [Jim Kirkbride](https://github.com/jameskbride)'s project 
[cmake-hello-world](https://github.com/jameskbride/cmake-hello-world.git) at 
(GitHub)[https://github.com/] as an example for developing a CMake project.

Run

`docker run --rm -it -v $(pwd):/workspaces docker-lab:0.0.1 "cd cmake-hello-world && cmake -S . -B build && cmake --build build"`

in this directory to build [Jim Kirkbride](https://github.com/jameskbride)'s project inside the container.

## Build and Run the other Images

To build the Apache 2 image run `docker build -f df_debian_apache -t apache:0.0.1 .`.
To run the container do something like `docker run -it --rm -p 4080:80 -p 4443:443 --name apache2 apache:0.0.1`



## Read Dokcer Docs Locally

You can run your docker doc server with `docker run -ti --rm --name dockerdocs -p 4000:4000 docs/docker.github.io`.

Open [http://localhost:4000/](http://localhost:4000/) in your browser.


## Clean Up Unused Images

The docker image prune command allows you to clean up unused images. By default, docker image prune 
only **cleans up dangling images**. A dangling image is one that is not tagged and is not referenced 
by any container. To remove dangling images run `docker image prune`.

To **remove all images which are not used by existing containers**, use the -a flag: `docker image prune -a`.

## Clean Up Unused Containers

If yout don't start a container with **--rm** flag it is not automatically removed when 
you stop it. Especially on a development system there may be many unused containers. To remove 
all stopped containers’ writable layers use `docker container prune`.

## Clean Up Unused Volumes

Volumes can be used by one or more containers, and take up space on the Docker host. Volumes are never 
removed automatically, because to do so could destroy data. To remove all unused volumes run
`docker volume prune`.

## Stop all running containers

    docker stop $(docker ps -q)

## List "dangling" images

    docker images -f "dangling=true"

## Delete "dangling" images

    docker rmi -f $(docker images -f "dangling=true" -q)

