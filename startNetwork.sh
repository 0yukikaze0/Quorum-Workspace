#!/usr/bin/env bash

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

    # Pre check -> Are the containers running
    echo " +- Systems check"
    for nodeName in $nodes
    do

        containerName=${networkName}_${nodeName}

        # Get current container state
        # If container is in stopped status -> Issue a start command
        containerStatus=$(docker inspect --format "{{ .State.Status }}" $containerName)
        echo "      [+] $containerName : $containerStatus"

        if [ "$containerStatus" == "exited" ]
        then
            echo "          +- Starting container $containerName"
            docker start $containerName >> /dev/null
        fi

    done

    # Start constellation nodes on all containers
    echo " +- Booting constellation"
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        eval roles="\$${nodeName}_roles"
        eval keyHex="\$${nodeName}_keyHex"
        eval port="\$${nodeName}_constellationPort"

        if [ "$roles" == "bootnode" ]
        then
            ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
            address=$(docker exec $containerName bootnode -writeaddress -nodekeyhex="$keyHex")
            eval bootNodePort="\$${nodeName}_port"
            BOOTNODE_ENODE="enode://${address}@[${ipAddr}]:${bootNodePort}"
            continue
        fi

        # If constellation is already running -> continue to next container
        constellationStatus=$(docker exec $containerName ps | grep "constellation*")
        if [ -z $constellationStatus ]
        then
            echo "      +- Starting constellation node on $containerName"
            docker  exec -d $containerName \
                    /bin/bash -c    "nohup constellation-node /data/quorum/constellation/constellation_${nodeName}.conf 2>> /data/quorum/logs/constellation_${nodeName}.log &"
            sleep 1
        else
            echo "      +- Detected an existing constellation process on $containerName -> [ $constellationStatus ]"
        fi
        
    done

    echo " +- Starting Quorum Nodes"
    for nodeName in $nodes
    do 
        containerName=${networkName}_${nodeName}
        eval roles="\$${nodeName}_roles"
        eval ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
        eval port="\$${nodeName}_port"
        eval rpcPort="\$${nodeName}_rpcPort"
        
        if [ "$roles" == "bootnode" ]
        then
            bootNodeStatus=$(docker exec $containerName ps | grep "bootnode*")            
            if [ -z $bootNodeStatus ]
            then
                eval keyHex="\$${nodeName}_keyHex"
                echo "      +- Starting bootnode @ $ipAddr"
                echo "          +- Boot Node Key : $keyHex"
                docker  exec -d $containerName \
                        /bin/bash -c "nohup bootnode --nodekeyhex "$keyHex" --addr="${ipAddr}:${port}" 2>>/data/quorum/logs/$nodeName.log &"                
            else
                echo "      +- Detected an existing bootnode process on $containerName -> [ $bootNodeStatus ]"                
            fi
            continue
        fi

        gethNodeStatus=$(docker exec $containerName ps | grep "geth*")        
        if [ -z $gethNodeStatus ]
        then
            roleString=""
            # Voter configuration
            if [ "$roles" != "${roles/voter/}" ]
            then
                eval voteAccount="\$${nodeName}_voteAccount"
                eval votePassword="\$${nodeName}_votePassword"
                roleString="$roleString --voteaccount \"$voteAccount\" --votepassword \"$votePassword\""
            fi

            # Blockmaker configuration
            if [ "$roles" != "${roles/blockmaker/}" ]
            then
                eval blockMakerAccount="\$${nodeName}_blockMakerAccount"
                eval blockMakerPassword="\$${nodeName}_blockPassword"
                eval minBlockTime="\$${nodeName}_minBlockTime"
                eval maxBlockTime="\$${nodeName}_maxBlockTime"
                roleString="$roleString --blockmakeraccount \"$blockMakerAccount\" --blockmakerpassword \"$blockMakerPassword\" --singleblockmaker --minblocktime $minBlockTime --maxblocktime $maxBlockTime"
            fi
            eval verbosity="\$${nodeName}_verbosity"
            echo "      +- Starting $containerName with roles [ $roles ]"        
            docker  exec -d $containerName      \
                    /bin/bash -c                \
                    "PRIVATE_CONFIG=/data/quorum/constellation/constellation_${nodeName}.conf \
                    nohup geth --datadir /data/quorum \
                    --bootnodes $BOOTNODE_ENODE \
                    --networkid $networkId  \
                    --solc /usr/bin/solc \
                    --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum \
                    --rpc --rpcaddr ${ipAddr} --rpcport $rpcPort --port $port \
                    $roleString \
                    --verbosity $verbosity \
                    2>>/data/quorum/logs/$nodeName.log &"    
        else
            echo "      +- Detected an existing geth process on $containerName -> [ $gethNodeStatus ]"            
        fi
                
    done

    # Echo current status
    printf "\n"
    echo " +---------------------------------------------------------------+"
    echo " |                      Active Quorum Nodes                      |"
    echo " +-----------------------+---------------+-----------------------+"   
    printf " | Container Name \t | IP Address \t | Roles \t\t |\n"
    echo " +-----------------------+---------------+-----------------------+"   
    for nodeName in $nodes
    do
        containerName=${networkName}_${nodeName}
        eval roles="\$${nodeName}_roles"
        eval ipAddr=$(docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName)
        printf " | %s \t | %s \t | %s \t\t \n" $containerName $ipAddr "$roles"

    done
    echo " +-----------------------+---------------+-----------------------+"   

    echo ""
    echo " +---------------------------------------------------------------+"
    echo " |                      Constellation Logs                       |"
    echo " +---------------------------------------------------------------+" 
    for nodeName in $nodes
    do
        echo "  $HOME/quorum/$networkName/datadirs/$nodeName/logs/constellation_${nodeName}.log"
    done
    echo " +---------------------------------------------------------------+" 

    echo ""
    echo " +---------------------------------------------------------------+"
    echo " |                          Quorum Logs                          |"
    echo " +---------------------------------------------------------------+" 
    for nodeName in $nodes
    do
        echo "  $HOME/quorum/$networkName/datadirs/$nodeName/logs/${nodeName}.log"
    done
    echo " +---------------------------------------------------------------+" 

    echo ""
    echo " +---------------------------------------------------------------+"
    echo " |                         Quorum IPC's                          |"
    echo " +---------------------------------------------------------------+" 
    for nodeName in $nodes
    do
        echo "  $HOME/quorum/$networkName/datadirs/$nodeName/geth.ipc"
    done
    echo " +---------------------------------------------------------------+" 

fi