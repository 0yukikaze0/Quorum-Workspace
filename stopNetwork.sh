#!/usr/bin/bash

# Author : Ashfaq Ahmed Shaik <https://github.com/0yukikaze0>
#
# Description : Stops geth containers for requested network

if [ -z "$1" ]
then echo "Network Name required. Usage: startNetwork.sh <networkName>"
else
    IFS=","
    networkName=$1
    if [ ! -f ./Networks/$networkName/$networkName.properties ]
    then 
        echo "Can't find $networkName.properties under ./Networks/$networkName"
        echo "Nothing to work on... Exiting"
        exit
    fi
    . ./Networks/$networkName/$networkName.properties
    
    echo " +- Stopping quorum network [ $networkName ]"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        echo "      +- Stopping $containerName"
        docker stop $containerName >> /dev/null
    done
fi