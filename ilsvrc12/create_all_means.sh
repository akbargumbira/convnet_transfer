#! /bin/bash -x

CONTAINER_IMAGENET_DIR=/home/data
IMAGENET_DIR=/home/agumbira/dev/data/imagenet/ilsvrc12/downsampled/downsampled

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
DOCKER_OPTIONS="--rm -ti -u $CUID:$CGID --volume=$(pwd):/workspace --volume=$IMAGENET_DIR:$CONTAINER_IMAGENET_DIR --workdir=/workspace"
DOCKER_RUN="$DOCKER_CMD run $DOCKER_OPTIONS $IMAGE"
sleep 5


create_tv ()
{
    submit GLOG_logtostderr=1 $DOCKER_RUN bash -c "'/opt/caffe/build/tools/compute_image_mean data/${1}_train/leveldb data/${1}_train/mean.binaryproto'"
    submit GLOG_logtostderr=1 $DOCKER_RUN bash -c "'/opt/caffe/build/tools/compute_image_mean data/${1}_valid/leveldb data/${1}_valid/mean.binaryproto'"
}

create_train ()
{
    submit GLOG_logtostderr=1 $DOCKER_RUN bash -c "'/opt/caffe/build/tools/compute_image_mean data/${1}_train/leveldb data/${1}_train/mean.binaryproto'"
}

submit ()
{
    echo "This will only work on a cluster supporting qsub. Modify if needed for your setup."

    jobname="mn_`date +%H%M%S`"
    echo "#! /bin/bash" >> $jobname.sh
    echo "$@" >> $jobname.sh
    chmod +x $jobname.sh
    # qsub -N "$jobname" -A ACCOUNT_NAME -l nodes=1:ppn=2 -l walltime=8:00:00 -d `pwd` $jobname.sh
    sh $jobname.sh
    sleep 1.5
}

# A/B halves
create_tv half0A
create_tv half0B
create_tv half1A
create_tv half1B
create_tv half2A
create_tv half2B
create_tv half3A
create_tv half3B

# Natural/Man-made halves
create_tv halfnatmanA
create_tv halfnatmanB

# Reduced volume datasets
create_train reduced0001
create_train reduced0002
create_train reduced0005
create_train reduced0010
create_train reduced0025
create_train reduced0050
create_train reduced0100
create_train reduced0250
create_train reduced0500
create_train reduced0750
create_train reduced1000
