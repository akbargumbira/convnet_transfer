#!/usr/bin/env sh
set -e

# The GPU-enabled version of Caffe can be used, assuming that nvidia-docker
# is installed, and the GPU-enabled Caffe image has been built.
# Setting the GPU environment variable to 1 will enable the use of nvidia-docker.
# e.g.
#   GPU=1 ./run.sh [ADDITIONAL_CAFFE_ARGS]
#
#


if [ x"$(uname -s)" != x"Linux" ]
then
echo ""
echo "This script is designed to run on Linux."
echo "There may be problems with the way Docker mounts host volumes on other"
echo "systems which will cause the docker commands to fail."
echo ""
read -p "Press [ENTER] to continue..." key
echo ""
fi


# Check if GPU mode has been enabled and set the docker executable accordingly
if [ ${GPU:-0} -eq 1 ]
then
DOCKER_CMD=nvidia-docker
IMAGE=bvlc/caffe:gpu
else
DOCKER_CMD=docker
IMAGE=bvlc/caffe:cpu
fi
echo "Using $DOCKER_CMD to launch $IMAGE"

# On non-Linux systems, the Docker host is typically a virtual machine.
# This means that the user and group id's may be different.
# On OS X, for example, the user and group are 1000 and 50, respectively.
if [ x"$(uname -s)" != x"Linux" ]
then
CUID=1000
CGID=50
else
CUID=$(id -u)
CGID=$(id -g)
fi

# Define some helper variables to make the running of the actual docker
# commands less verbose.
# Note:
#   -u $CUID:$CGID             runs the docker image as the current user to ensure
#                              that the file permissions are compatible with the
#                              host system. The variables CUID and CGID have been
#                              set above depending on the host operating system.
#   --volume $(pwd):/workspace mounts the current directory as the docker volume
#                              /workspace
#   --workdir /workspace       Ensures that the docker container starts in the right
#                              working directory
DOCKER_OPTIONS="--rm -ti -u $CUID:$CGID --volume=$(pwd):/workspace --volume=$(pwd)/../../ilsvrc12/data/half0A_train/leveldb:/workspace/imagenet_train_leveldb --volume=$(pwd)/../../ilsvrc12/data/half0A_valid/leveldb:/workspace/imagenet_val_leveldb --workdir=/workspace"
DOCKER_RUN="$DOCKER_CMD run $DOCKER_OPTIONS $IMAGE"

# Train the network
$DOCKER_RUN caffe train --solver=lenet_solver.prototxt $*
#$DOCKER_RUN bash -c "ls imagenet_train_leveldb"
