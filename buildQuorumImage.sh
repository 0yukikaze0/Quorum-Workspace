#!/usr/bin/env bash

echo "Building quorum image with proxy parameter : $1"

docker build    --build-arg PROXY=$1                        \
                -f ./Docker/dockerfile                      \
                -t yukikaze/quorum:1.1.0 .
                 