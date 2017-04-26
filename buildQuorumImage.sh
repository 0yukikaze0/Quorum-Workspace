#!/usr/bin/bash

echo "Running docker build with proxy param : $1"

docker build    --build-arg PROXY=$1                        \
                -f ./Docker/dockerfile                      \
                -t broadridge/quorum:1.1.0 .
                 