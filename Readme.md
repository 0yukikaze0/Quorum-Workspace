# Quorum Workspace

Quick deploy system for [Quorum](https://github.com/jpmorganchase/quorum) networks

This project provides a docker based approach to deploy multiple isolated Quorum networks, providing developers the ability to create sandboxes and play around.

Tested on _Ubuntu 16.04_ & _RHEL 7.x_

### Future release enhancements
* Auto config via minimal user prompts
* Constellation password management
* Web based monitoring/one click deploy?? 


## Prerequisites 
1. Docker
2. Quorum Docker image
    * Run `buildQuorumImage.sh` -> If behind proxy Run `buildQuorumImage.sh http://proxyaddress>`
    * or
    * Pull from docker hub `docker pull yukikaze/quorum:1.1.0` 

## Quick start

A default and ready to deploy network configuration named `TestNet` is provided under Networks folder. For the remainder of this guide, we would be referring to TestNet. 

Skip to step 2 if you are not interested in configuring your own network.

1. Configure network parameters (In case you want to spin a new isolated network)
    * Assuming your network would be named `bifrost`
    * Create folders in `Networks` directory -> `Networks/bifrost`, `Networks/bifrost/genesis`, `Networks/keypairs`
    * Create properties file named `bifrost.properties` (mimic TestNet.properties)
    * Place keypairs in `Networks/bifrost/`
2. Run `initNetwork.sh TestNet`
    * **Caution** :This is a desctructive action and will delete any pre existing data for this network. Run this step only if 1) This is your first deployment 2) You want to reset your quorum network
    * This script will create the scaffolding and build your network as per the configuration in TestNet.properties
    * Further down the process, it would prompt for a password for constellation keys. Hit enter and donot set a password. Password management would be in place in a future release
3. Run `startNetwork TestNet`
    * This script will start constellation and geth in all of the running containers.
    * A summary would be printed in the end on ip's, log locations, IPC paths

```
 +---------------------------------------------------------------+`
 |                      Active Quorum Nodes                      |
 +-----------------------+---------------+-----------------------+
 | Container Name 	 | IP Address 	 | Roles 		 |
 +-----------------------+---------------+-----------------------+
 | TestNet_Boot 	 | 172.20.0.2 	 | bootnode 		 
 | TestNet_Node1 	 | 172.20.0.3 	 | read 		 
 | TestNet_Node2 	 | 172.20.0.4 	 | voter,blockmaker 		 
 | TestNet_Node3 	 | 172.20.0.5 	 | read 		 
 | TestNet_Node4 	 | 172.20.0.6 	 | voter 		 
 | TestNet_Node5 	 | 172.20.0.7 	 | voter 		 
 | TestNet_Node6 	 | 172.20.0.8 	 | read 		 
 | TestNet_Node7 	 | 172.20.0.9 	 | read 		 
 +-----------------------+---------------+-----------------------+

 +---------------------------------------------------------------+
 |                      Constellation Logs                       |
 +---------------------------------------------------------------+
  /home/ashfaq/quorum/TestNet/datadirs/Boot/logs/constellation_Boot.log
  /home/ashfaq/quorum/TestNet/datadirs/Node1/logs/constellation_Node1.log
  /home/ashfaq/quorum/TestNet/datadirs/Node2/logs/constellation_Node2.log
  /home/ashfaq/quorum/TestNet/datadirs/Node3/logs/constellation_Node3.log
  /home/ashfaq/quorum/TestNet/datadirs/Node4/logs/constellation_Node4.log
  /home/ashfaq/quorum/TestNet/datadirs/Node5/logs/constellation_Node5.log
  /home/ashfaq/quorum/TestNet/datadirs/Node6/logs/constellation_Node6.log
  /home/ashfaq/quorum/TestNet/datadirs/Node7/logs/constellation_Node7.log
 +---------------------------------------------------------------+

 +---------------------------------------------------------------+
 |                          Quorum Logs                          |
 +---------------------------------------------------------------+
  /home/ashfaq/quorum/TestNet/datadirs/Boot/logs/Boot.log
  /home/ashfaq/quorum/TestNet/datadirs/Node1/logs/Node1.log
  /home/ashfaq/quorum/TestNet/datadirs/Node2/logs/Node2.log
  /home/ashfaq/quorum/TestNet/datadirs/Node3/logs/Node3.log
  /home/ashfaq/quorum/TestNet/datadirs/Node4/logs/Node4.log
  /home/ashfaq/quorum/TestNet/datadirs/Node5/logs/Node5.log
  /home/ashfaq/quorum/TestNet/datadirs/Node6/logs/Node6.log
  /home/ashfaq/quorum/TestNet/datadirs/Node7/logs/Node7.log
 +---------------------------------------------------------------+

 +---------------------------------------------------------------+
 |                         Quorum IPC's                          |
 +---------------------------------------------------------------+
  /home/ashfaq/quorum/TestNet/datadirs/Boot/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node1/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node2/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node3/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node4/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node5/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node6/geth.ipc
  /home/ashfaq/quorum/TestNet/datadirs/Node7/geth.ipc
 +---------------------------------------------------------------+
```

4. To stop an existing network, Run `stopNetwork.sh TestNet`



