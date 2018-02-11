#!/bin/bash
pushd "$(dirname $0)" > /dev/null
docker build . -t snyltrecept
docker run -v "$(pwd):/app" -it snyltrecept "$@"
popd > /dev/null
