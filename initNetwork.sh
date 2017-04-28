#!/usr/bin/bash

# Author : Ashfaq Ahmed Shaik <https://github.com/0yukikaze0>
#
# Description : Builds and configures scaffolding for a Quorum network. Nodes are deployed
#               as docker containers.
#
# CAUTION : Destructive actions => This script will delete any previous blockchain instance
#           running with the same name. Previous data/state will be lost and a new genesis 
#           block will be created
#           

# Build local data directories to be mounted as volumes on containers
# Let $networkName = current network name
# Genesis           : $HOME/quorum/$networkName/genesis/genesis.json
# Data Directories  : $HOME/quorum/$networkName/datadirs/$nodeName
# Keystores         : $HOME/quorum/$networkName/datadirs/$nodeName/keystore
# Constellation     : $HOME/quorum/$networkName/datadirs/$nodeName/constellation/keystore
# logs              : $HOME/quorum/$networkName/datadirs/$nodeName/logs

if [ -z "$1" ]
then echo "Network Name required. Usage: initNetwork.sh <networkName>"
else
    echo "+-----------------------------------------------------------------+"
    echo "|                  Quorum Workspace Builder v1.0                  |"
    echo "+-----------------------------------------------------------------+"
    IFS=","
    networkName=$1
    if [ ! -f ./Networks/$networkName/$networkName.properties ]
    then 
        echo "Can't find $networkName.properties under ./Networks/$networkName"
        echo "Nothing to work on... Exiting"
        exit
    fi
    . ./Networks/$networkName/$networkName.properties

    # Stop any pre existing nodes for this network
    echo " +- Stopping pre existing nodes for [ $networkName ]"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        echo "      +- Stopping $containerName"        
        docker exec $containerName rm -rf /data/quorum/geth && rm -rf /data/quorum/keystore && rm -rf /data/quorum/logs && rm -rf /data/quorum/constellation
        docker stop $containerName > /dev/null && docker rm $containerName > /dev/null
    done

    # Clear and create directories
    echo " +- Building quorum network : $networkName"
    echo " +- Clearing any pre-existing [ $networkName ] data"
    rm -rf $HOME/quorum/$networkName
    mkdir -p $HOME/quorum/$networkName/genesis
    
    echo " +- Installing Genesis JSON"
    cp ./Networks/$networkName/genesis/genesis.json $HOME/quorum/$networkName/genesis/genesis.json
    
    echo " +- Creating silos"
    for nodeName in $nodes
    do 
        mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName/logs
        echo "      +- Creating silo for [ $nodeName ]"
        mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName
        echo "          +- Data directory : $HOME/quorum/$networkName/datadirs/$nodeName"
        mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName/keystore
        echo "          +- Key Store : $HOME/quorum/$networkName/datadirs/$nodeName/keystore"
        
        eval roles="\$${nodeName}_roles"
        if [ "$roles" != "bootnode" ]
        then
            echo "          +- Installing bootstrap keys"        
            # Install bootstrap key pairs
            eval keys="\$${nodeName}_keys"
            for key in $keys
            do
                cp ./Networks/$networkName/Keypairs/$key $HOME/quorum/$networkName/datadirs/$nodeName/keystore
            done

            # Install keypairs for constellation
            echo "          +- Installing constellation keys"
            mkdir -p $HOME/quorum/$networkName/datadirs/$nodeName/constellation/keystore
            eval constellationKeys="\$${nodeName}_constellationKeys"
            for key in $constellationKeys
            do
                # Key name format
                # <nodeName>_tm
                extension=${key##*.}
                cp ./Networks/$networkName/constellation/keys/$key $HOME/quorum/$networkName/datadirs/$nodeName/constellation/keystore/${nodeName}_tm.${extension}
            done

        fi

        echo ""

    done

    # Initialize Quorum Nodes
    #   Container name      : <networkName>_<nodeName>
    #   Docker network name : <networkName>
    #
    #   1. Delete any pre existing docker network
    #   2. Create docker network
    #   3. Spin up node containers

    # [1]
    echo " +- Removing docker network [ $networkName ]"
    docker network rm $networkName > /dev/null
    # [2]
    echo " +- Creating network [ $networkName ]"
    docker network create --driver=bridge $networkName > /dev/null
    # [3]
    echo " +- Spinning up node containers"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        echo "      +- Spinning up $containerName"
        eval rpcPort="\$${nodeName}_rpcPort"
        docker  run -td                             \
                --name $containerName               \
                --network $networkName              \
                -v $HOME/quorum/$networkName/genesis:/data/genesis              \
                -v $HOME/quorum/$networkName/datadirs/$nodeName:/data/quorum    \
                -p $rpcPort:$rpcPort                \
                broadridge/quorum:1.1.0 > /dev/null
    done

    printf "\n"
    echo " +---------------------------------------+"
    echo " |          Active Quorum Nodes          |"
    echo " +-----------------------+---------------+"   
    printf " | Container Name \t | IP Address \t | \n"
    echo " +-----------------------+---------------+"   
    
    # Get IP addresses of all running containers
    # Build Constellation properties
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
        printf " | %s \t | %s \t | \n" $containerName $ipAddr

        eval roles="\$${nodeName}_roles"
        if [ "$roles" == "bootnode" ]
        then
            continue
        fi

        
        echo ""
        # Write constellation Properties
        eval port="\$${nodeName}_constellationPort"
        eval url="http://$ipAddr:$port/"
        socketPath="/data/quorum/constellation/constellation_${nodeName}.ipc"
        eval otherNodeUrls="\$${nodeName}_constellationOtherNodeUrls"
        constPath="$HOME/quorum/$networkName/datadirs/$nodeName/constellation"

        echo "url=\"$url\"" >> $constPath/constellation_$nodeName.conf
        echo "port=$port" >> $constPath/constellation_$nodeName.conf
        echo "socket=\"$socketPath\"" >> $constPath/constellation_$nodeName.conf
        echo "othernodes=$otherNodeUrls" >> $constPath/constellation_$nodeName.conf
        echo "publicKeyPath=\"/data/quorum/constellation/keystore/${nodeName}_tm.pub\"" >> $constPath/constellation_$nodeName.conf
        echo "privateKeyPath=\"/data/quorum/constellation/keystore/${nodeName}_tm.key\"" >> $constPath/constellation_$nodeName.conf
        echo "archivalPublicKeyPath=\"/data/quorum/constellation/keystore/${nodeName}_archival.key\"" >> $constPath/constellation_$nodeName.conf
        echo "archivalPrivateKeyPath=\"/data/quorum/constellation/keystore/${nodeName}_archival.key\"" >> $constPath/constellation_$nodeName.conf
        echo "storagePath=\"/data/quorum/constellation\"" >> $constPath/constellation_$nodeName.conf

    done
    echo " +-----------------------+---------------+"

    echo ""

    echo " +- Generating enclave keypairs"
    for nodeName in $nodes
    do
        # Generate constellation keypairs
        containerName=${networkName}_${nodeName}
        echo "      +- Generating keypair for $containerName"
        docker  exec $containerName  \
                /bin/bash -c "constellation-enclave-keygen /data/quorum/constellation/keystore/${containerName}_tm"
        docker  exec $containerName  \
                /bin/bash -c "constellation-enclave-keygen /data/quorum/constellation/keystore/${containerName}_archival"
    done

    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        eval roles="\$${nodeName}_roles"

        if [ "$roles" == "bootnode" ]
        then
            continue
        else
            echo " +- Creating genesis block on $containerName"
            echo ""
            docker  exec $containerName  \
                    geth --datadir /data/quorum init /data/genesis/genesis.json
        fi
        
        echo ""
    done

    echo "+-----------------------------------------------------------------+"
    echo "|                  Quorum Nodes Initialized                       |"
    echo "+-----------------------------------------------------------------+"
fi