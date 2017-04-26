#!/usr/bin/bash

# Author : Ashfaq Ahmed Shaik <https://github.com/0yukikaze0>
#
# Description : Starts geth on all preconfigured quorum containers

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
    BOOTNODE_ENODE=""

    # Start constellation nodes on all containers
    echo " +- Booting constellation"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        eval roles="\$${nodeName}_roles"
        if [ "$roles" == "bootnode" ]
        then
            eval keyHex="\$${nodeName}_keyHex"
            eval port="\$${nodeName}_port"
            ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
            address=$(docker exec $containerName bootnode -writeaddress -nodekeyhex="$keyHex")
            BOOTNODE_ENODE="enode://${address}@[${ipAddr}]:${port}"
            continue
        fi

        echo "      +- Starting constellation node on $containerName"
        docker  exec -d $containerName \
                /bin/bash -c "nohup constellation-node /data/quorum/constellation/constellation_${nodeName}.conf 2>> /data/quorum/logs/constellation_${nodeName}.log --socket=/data/quorum/constellation/constellation_${nodeName}.ipc &"
        sleep 1

    done

    GLOBAL_ARGS="--bootnodes $BOOTNODE_ENODE --networkid $networkId  --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"
    echo " +- Starting Quorum Nodes"
    for nodeName in $nodes
    do 
        containerName=${networkName}_${nodeName}
        eval roles="\$${nodeName}_roles"
        if [ "$roles" == "bootnode" ]
        then
            continue
        fi
        eval ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
        eval port="\$${nodeName}_port"
        eval rpcPort="\$${nodeName}_rpcPort"

        execString="PRIVATE_CONFIG=/data/quorum/constellation/constellation_${nodeName}.conf nohup geth --datadir /data/quorum $GLOBAL_ARGS --rpc --rpcaddr ${ipAddr} --rpcport $rpcPort --port $port"

        # Voter configuration
        if [ "$roles" != "${roles/voter/}" ]
        then
            eval voteAccount="\$${nodeName}_voteAccount"
            eval votePassword="\$${nodeName}_votePassword"
            execString="$execString --voteaccount \"$voteAccount\" --votepassword \"$votePassword\""
        fi

        # Blockmaker configuration
        if [ "$roles" != "${roles/blockmaker/}" ]
        then
            eval blockMakerAccount="\$${nodeName}_blockMakerAccount"
            eval blockMakerPassword="\$${nodeName}_blockPassword"
            eval minBlockTime="\$${nodeName}_minBlockTime"
            eval maxBlockTime="\$${nodeName}_maxBlockTime"
            execString="$execString --blockmakeraccount \"$blockMakerAccount\" --blockmakerpassword \"$blockMakerPassword\" --singleblockmaker --minblocktime $minBlockTime --maxblocktime $maxBlockTime"
        fi

        echo "      +- Starting $containerName with roles [ $roles ]"
        docker  exec -d $containerName      \
                /bin/bash -c                \
                "$execString 2>>/data/quorum/logs/$nodeName.log &"
           
    done

fi