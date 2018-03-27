# drp-test
Test harness using *Digital Rebar* and *InfraSim* for Infrastructure Management

# Overview

This project leverages the great work on the [InfraSim](https://github.com/InfraSIM) project to simulate bare-metal nodes with IPMI support.


# Dependencies

Docker
VNCViewer
All other functions are provided by the scripts in repo. There were some modifications to original scripts.


# Configuration

**global.json**

Preset workflow configuration for RackN to install CentOS7


**subnet.json**

Preset DHCP scope for test. Check gateway and DNS for your setup


**default.yml**

Default Infrasim configuration.



Other variables are stored in MakeFile
- VNCVIEWER variable to bring up the terminal of the virtualized host. 
- DRP_LINK_ADDR Non Docker managed interface setup with PipeWorks


# Network Setup

This demo runs all components in Docker containers and leverages the great [Pipework](https://github.com/jpetazzo/pipework) script by jpetazzi


[Network](docs/drp.png "Network")

# Geting Started

Command List

```
clean-all                      Stop DRP container and pull from from DockerHub
clean-nodes                    Stop and remove node containers
create-nodes                   Create Node Simulators <NODES>=integer
docker-pull                    Pull image from docker
download                       Git clone repo
drp-configure                  Configure DRP server with iso, bootenv and subnet profile
drp-isos                       Show loaded isos
drp-run                        Startup DRP container and bind provisioning interface to br0
drp-showlogs                   Watch DRP logs
drp-subnets                    Show loaded isos
drp-update-profile             Update Global profile
drp-uploadiso                  Upload standard ISOS and set bootenv
git-pull                       Pull image from GitHub
stop                           Stop all simulator services

```

1. Launch DRP server

```make drp-run```

2. Install IPMI Plugin
	This requires a trial from RackN as the IPMI plugin is part of enterprise edition. See http://rebar.digital/ for documentation

3. Configure DRP

```make drp-configure```

5. Optionally run a log watcher

```make drp-showlogs```

6. Create Infrasim Nodes

```make create-nodes NODES=<1-n>```


# Demo

<a href="http://www.youtube.com/watch?feature=player_embedded&v=u5oeyFipckQ" target="_blank"><img src="http://img.youtube.com/vi/u5oeyFipckQ/0.jpg" 
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>





