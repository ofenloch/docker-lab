# syntax=docker/dockerfile:1
FROM debian:11.1

#
# build the image                        
#           docker build -t docker-lab:0.0.1 .
#
# execute a command in the container
#           docker run --rm --namt docker-lab -it -v $(pwd):/workspaces docker-lab:0.0.1 "ls -hal /workspaces"
#

LABEL maintainer="Oliver Ofenloch <57812959+ofenloch@users.noreply.github.com>"
LABEL version="0.0.1"

# The VOLUME instruction creates a mount point with the specified name and 
# marks it as holding externally mounted volumes from native host or other 
# containers. The value can be a JSON array, VOLUME ["/var/log/"], or a 
# plain string with multiple arguments, such as VOLUME /var/log or 
# VOLUME /var/log /var/db. For more information/examples and mounting 
# instructions via the Docker client, refer to 
# [Share Directories via Volumes](https://docs.docker.com/storage/volumes/) documentation.
#
# The docker run command initializes the newly created volume with any data 
# that exists at the specified location within the base image.
VOLUME "/workspaces"

# The WORKDIR instruction sets the working directory for any RUN, CMD, 
# ENTRYPOINT, COPY and ADD instructions that follow it in the Dockerfile. 
# If the WORKDIR doesn’t exist, it will be created even if it’s not used 
# in any subsequent Dockerfile instruction.
# The WORKDIR instruction can be used multiple times in a Dockerfile. If a 
# relative path is provided, it will be relative to the path of the previous 
# WORKDIR instruction.
WORKDIR "/workspaces"

# This is for my apt-cacher (adjust to your needs):
COPY ./assets/apt.conf.proxy /etc/apt/apt.conf.d/01proxy

# set environment variable for apt-get:
ENV DEBIAN_FRONTEND=noninteractive


# Docker has a set of predefined ARG variables that you can use without a corresponding ARG instruction in the Dockerfile.
#
#   HTTP_PROXY
#   http_proxy
#   HTTPS_PROXY
#   https_proxy
#   FTP_PROXY
#   ftp_proxy
#   NO_PROXY
#   no_proxy
#
# To use these, pass them on the command line using the --build-arg flag, for example:
#
#   $ docker build --build-arg HTTPS_PROXY=https://my-proxy.example.com .
# By default, these pre-defined variables are excluded from the output of docker history. Excluding them 
# reduces the risk of accidentally leaking sensitive authentication information in an HTTP_PROXY variable.


# configure a user inside the container (adjust to your needs):
ARG USER_NAME="ofenloch"
ARG USER_GROUP="ofenloch"
ARG USER_UID="6534"
ARG USER_GID="4356"
ARG USER_HOME="/home/${USER_NAME}"
ARG USER_SHELL="/bin/bash"

# install some software (adjust to your needs):
RUN /usr/bin/apt-get update && \
    /usr/bin/apt-get --yes --no-install-recommends --fix-broken --fix-missing install \
        apt-utils && \
    /usr/bin/apt-get --yes --no-install-recommends --fix-broken --fix-missing install \
        bash \
        build-essential \
        ccache \
        cmake \
        cppcheck \
        doxygen \
        g++ \
        gcc \
        openssl \
        pwgen && \
    /bin/rm -rf /var/cache/apt/*

# create the user:
RUN USER_PASSWD=$(/usr/bin/pwgen --capitalize --numerals --symbols 10 1) && \
    USER_PASSWD_ENCRYPTED="$(echo ${USER_PASSWD} | /usr/bin/openssl passwd -1 -stdin )" && \
    echo "USER_NAME             = ${USER_NAME}" >> /root/image-user.txt && \
    echo "USER_UID              = ${USER_UID} " >> /root/image-user.txt && \
    echo "USER_GROUP            = ${USER_GROUP} " >> /root/image-user.txt && \
    echo "USER_GID              = ${USER_GID} " >> /root/image-user.txt && \
    echo "USER_HOME             = ${USER_HOME}" >> /root/image-user.txt && \
    echo "USER_SHELL            = ${USER_SHELL}" >> /root/image-user.txt && \
    echo "USER_PASSWD           = ${USER_PASSWD}" >> /root/image-user.txt && \
    echo "USER_PASSWD_ENCRYPTED = ${USER_PASSWD_ENCRYPTED}" >> /root/image-user.txt && \
    echo "creating user ${USER_NAME}:${USER_GROUP} (${USER_UID}:${USER_GID}) ..." && \
    /usr/sbin/groupadd --force --gid ${USER_GID} ${USER_GROUP} && \
    /usr/sbin/useradd --create-home --gid=${USER_GID} --uid=${USER_UID} \
    --shell=${USER_SHELL} --home-dir=${USER_HOME} \
    --password=${USER_PASSWD_ENCRYPTED} ${USER_NAME}

USER ${USER_NAME}:${USER_NAME}

# Define the ENTRYPOINT
#
# The ENTRYPOINT allows you to configure a container that will run as an executable.
# Command line arguments to docker run <image> will be appended after all elements in 
# an exec form ENTRYPOINT, and will override all elements specified using CMD. This 
# allows arguments to be passed to the entry point, i.e., docker run <image> -d will 
# pass the -d argument to the entry point. You can override the ENTRYPOINT instruction 
# using the docker run --entrypoint flag.
#
# We chose "/bin/bash -c" as ENTRYPOINT (this is the exec form, which is the preferred form).
#
# /bin/bash: "If the -c option is present, then commands are read from the first non-option argument command_string.  If 
#             there are arguments after the command_string, the first  argument  is assigned to $0 and any remaining 
#             arguments are assigned to the positional parameters.  The assignment to $0 sets the name of the shell, which 
#             is used in warning and error messages."
#
# This means: The container executes /bin/bash -c "the given argument" and terminates after the command is done.
# So, calling 
#              docker run --rm -it -v $(pwd):/workspaces cpp-dev:0.0.1 "ls -hal /workspaces"
# starts the container, runs the given command (i.e. "ls -hal /workspaces") in bash and terminates.
#
# To keep the conatiner alive, we would need an ENTRYPOINT that does never finish ...
#
#
ENTRYPOINT [ "/bin/bash", "-c" ]

# We could do this, for example:
#             docker run --rm --name test -v $(pwd):/workspaces docker-lab:0.0.1 "sleep infinity"
# and then go into the container with something like
#             docker exec -it test bash
#
# Note: If we don't pass a name (e.g. `--name=test`) to the `docker run` command the name of the container 
# changes at each startup, check with `docker ps`.
#
# Note: In development (and sometimes in production) it is a good idea to pass `--rm` to the
# `docker run` command. This way the container gets deleted when it is shut down.