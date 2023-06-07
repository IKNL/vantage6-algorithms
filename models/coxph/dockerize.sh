#!/bin/bash
HOST='harbor.vantage6.ai'
PKG_NAME=${PWD##*/}
IMAGE="vantage/$PKG_NAME"
TAG='test'

echo "************************************************************************"
echo "* Building image '$IMAGE:$TAG' "
echo "************************************************************************"


if [ -n "$1" ]
then
    TAG=$1
fi

# The custom R base adds a few linux packages (openssl & xml2)
# Additionally, it installs the R packages in 'install_base_packages.R'
# to speedup building the image container this package's source.
docker build \
   -f docker/Dockerfile.custom-r-base \
   -t custom-r-base \
   .

# Build the docker image containing the local algorithm
# docker build --no-cache -f docker/Dockerfile -t $IMAGE:$TAG -t $HOST/$IMAGE:$TAG .
docker build \
  -f docker/Dockerfile \
   --build-arg PKG_NAME=$PKG_NAME \
  -t $IMAGE:$TAG \
  -t $HOST/$IMAGE:$TAG \
  .

# Push the new image to the registry
docker push $HOST/$IMAGE:$TAG


# This only works on macOS
if [ -x "$(command -v osascript)" ]
then
    NOTIFICATION_TXT="docker build of '$IMAGE' finished"
    NOTIFICATION_TITLE='docker'
    osascript << EOF
    display notification "$NOTIFICATION_TXT"¬
    with title "$NOTIFICATION_TITLE"¬
    sound name "Submarine"
EOF

fi