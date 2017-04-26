#!/usr/bin/bash

# Author : Ashfaq Ahmed Shaik <https://github.com/0yukikaze0>
#
# CAUTION : Destructive actions => This script will delete any previous blockchain instance
#           running with the same name. Previous data/state will be lost and a new genesis 
#           block will be created
#           

# Build a local data directory
# Let $networkName = current network name
# Genesis           : $HOME/quorum/$networkName/genesis/genesis.json
# Data Directories  : $HOME/quorum/$networkName/datadirs/$nodeName
# Keystores         : $HOME/quorum/$networkName/datadirs/$nodeName/keystore
# Constellation     : $HOME/quorum/$networkName/datadirs/$nodeName/constellation/keystore
# logs              : $HOME/quorum/$networkName/datadirs/$nodeName/logs


if [ -z "$1" ]
then echo "Network Name required. Usage: initNetwork.sh <networkName>"
else
    networkName=$1
    . ./Networks/$networkName/$networkName.properties
    echo " +- Building quorum network : $networkName"
    echo " +- Clearing any pre-existing [ $networkName ] data"
    rm -rf $HOME/quorum/$networkName
    mkdir -p $HOME/quorum/$networkName/genesis
    mkdir -p $HOME/quorum/$networkName/logs
    echo " +- Installing Genesis JSON"
    cp ./Networks/$networkName/genesis/$genesisFile $HOME/quorum/$networkName/genesis/genesis.json
    
    IFS=","
    echo " +- Creating silos"
    for nodeName in $nodes
    do 
        
        echo "      +- Creating silo for [ $nodeName ]"
        mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName
        echo "          +- Data directory : $HOME/quorum/$networkName/datadirs/$nodeName"
        mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName/keystore
        echo "          +- Key Store : $HOME/quorum/$networkName/datadirs/$nodeName/keystore"
        
        echo "          +- Installing bootstrap keys"
        # Install bootstrap key pairs
        eval keys="\$${nodeName}_keys"
        for key in $keys
        do
            cp ./Networks/$networkName/Keypairs/$key $HOME/quorum/$networkName/datadirs/$nodeName/keystore
        done

        echo "          +- Installing constellation keys"
        mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName/constellation/keystore
        eval constellationKeys="\$${nodeName}_constellationKeys"
        for key in $constellationKeys
        do
            cp ./Networks/$networkName/constellation/keys/$key $HOME/quorum/$networkName/datadirs/$nodeName/constellation/keystore
        done

        echo ""

    done

    # Initialize Quorum Nodes
    #   Container name      : <networkName>_<nodeName>
    #   Docker network name : <networkname>
    #
    #   1. Stop & remove any preexisting docker containers
    #   2. Delete any pre existing docker network
    #   3. Create docker network
    #   4. Spin up node containers

    # [1]
    echo " +- Stopping pre existing nodes for [ $networkName ]"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        echo "      +- Stopping $containerName"
        docker stop $containerName > /dev/null && docker rm $containerName > /dev/null
    done

    # [2]
    echo " +- Removing docker network [ $networkName ]"
    docker network rm $networkName > /dev/null
    # [3]
    echo " +- Creating network [ $networkName ]"
    docker network create --driver=bridge $networkName > /dev/null

    # [4]
    echo " +- Spinning up node containers"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        echo "      +- Spinning up $containerName"
        eval rpcPort="\$${nodeName}_rpcPort"
        docker  run -td                             \
                --name $containerName               \
                --network $networkName              \
                -v $HOME/quorum/$networkName/genesis:/data/quorum/genesis               \
                -v $HOME/quorum/$networkName/datadirs/$nodeName:/data/quorum/data       \
                -v $HOME/quorum/$networkName/logs:/data/quorum/logs                     \
                -p $rpcPort:$rpcPort                \
                broadridge/quorum:1.1.0 > /dev/null
    done

    printf "\n"
    printf " Active Quorum Nodes \n"
    printf " + \t\t\t + \t\t + \n"
    printf " | Container Name \t | IP Address \t | \n"
    printf " + \t\t\t + \t\t + \n"
    # Get IP addresses of all running containers
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
        printf " | %s \t | %s \t | \n" $containerName $ipAddr
    done
    printf " + \t\t\t + \t\t + \n"

    echo ""
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        echo " +- Creating genesis block on $containerName"
        echo ""
        docker  exec $containerName  \
                geth --datadir /data/quorum/data init /data/quorum/genesis/genesis.json
        echo ""
    done

    echo "+-----------------------------------------------------------------+"
    echo "|                  Quorum Nodes Initialilzed                      |"
    echo "+-----------------------------------------------------------------+"
fi