# Quorum Workspace

Quick deploy system for [Quorum](https://github.com/jpmorganchase/quorum) networks

This project provides a docker based approach to deploy multiple isolated Quorum networks, providing developers to create sandboxes and play around.

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
4. To stop an existing network, Run `stopNetwork.sh TestNet`



