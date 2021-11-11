# syntax=docker/dockerfile:1
FROM debian:11.1

#
# build the image                        docker build -t docker-lab:0.0.1 .
#
# execute a command in the container     docker run --rm -it -v $(pwd):/workspace docker-lab:0.0.1 "ls -hal /workspace"
#


LABEL maintainer="Oliver Ofenloch <57812959+ofenloch@users.noreply.github.com>"
LABEL version="0.0.1"

VOLUME "/workspace"

WORKDIR "/workspace"

# This is for my apt-cacher (adjust to your needs):
COPY ./assets/apt.conf.proxy /etc/apt/apt.conf.d/01proxy

# set environment variable for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# configure a user inside the container (adjust to your needs)
ENV NEW_USER_NAME=ofenloch
ENV NEW_UID=6534
ENV NEW_GID=4356
ENV HOME_DIRECTORY=/home/${NEW_USER_NAME}
ENV SHELL=/bin/bash
# create an encrypted passwort with
#     echo "MyPassword" | /usr/bin/openssl passwd -1 -stdin
# and save the result in NEW_PASSWD_ENCRYPTED
ENV NEW_PASSWD_ENCRYPTED="$1$LFpGO69v$WuxvOirMbMc2LTGulKdsr/"

# install some software  (adjust to your needs)
RUN /usr/bin/apt-get update && \
    /usr/bin/apt-get --yes --no-install-recommends --fix-broken --fix-missing install \
        apt-utils && \
    /usr/bin/apt-get --yes --no-install-recommends --fix-broken --fix-missing install \
        build-essential \
        gcc \
        g++ \
        cmake \
        ccache \
        bash \
        cppcheck \
        doxygen && \
    /bin/rm -rf /var/cache/apt/*


RUN /usr/sbin/groupadd --force --gid ${NEW_GID} ${NEW_USER_NAME} && \
    /usr/sbin/useradd --create-home --gid=${NEW_GID} --uid=${NEW_UID} \
    --shell=${SHELL} --home-dir=${HOME_DIRECTORY} \
    --password=${NEW_PASSWD_ENCRYPTED} ${NEW_USER_NAME}

USER ${NEW_USER_NAME}:${NEW_USER_NAME}

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
#              docker run --rm -it -v $(pwd):/workspace cpp-dev:0.0.1 "ls -hal /workspace"
# starts the container, runs the given command (i.e. "ls -hal /workspace") in bash and terminates.
#
# To keep the conatiner alive, we would need an ENTRYPOINT that does never finish ...
#
#
ENTRYPOINT [ "/bin/bash", "-c" ]

# We could do this, for example:
#             docker run --rm -v $(pwd):/workspace cpp-dev-openmodelica:0.0.1 "sleep infinity"
# and then go into the container with something like
#             docker exec -it beautiful_hugle bash
# The name of the container cahnges at each startup, check with `docker ps`.
