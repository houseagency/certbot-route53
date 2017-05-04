#!/bin/bash
pushd "$(dirname $0)" > /dev/null

docker build . -t snyltrecept
docker run -v $(pwd):/app -e "DOMAINS=$1" -e "EMAIL=$2" -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -it snyltrecept

popd > /dev/null

