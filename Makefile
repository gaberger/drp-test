# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)
# SHELL := /bin/bash
NAME := drp-test
PKG := github.com/gaberger/$(NAME)

# Set any default go build tags
BUILDTAGS :=

VERSION := $(shell cat VERSION.txt)

VNCVIEWER := vncviewer

DRP_LINK_ADDR=192.168.1.10/24

.DEFAULT_GOAL := help

stop: ## Stop all simulator services
	@echo "+ $@"
	docker stop drp

git-pull: ## Pull image from GitHub
	@echo "+ $@"
	@pushd provision && \
	git pull https://github.com/digitalrebar/provision && \
	popd

.PHONY: docker-pull
docker-pull: ## Pull image from docker
	@echo "+ $@"
	@docker stop drp &2>/dev/null && \
	docker pull digitalrebar/provision:latest

.PHONY: download
download:  ## Git clone repo
	@echo "+ $@"
	@git clone https://github.com/digitalrebar/provision

.PHONY: clean-all
clean-all: ## Stop DRP container and pull from from DockerHub
	@echo "+ $@"
	@docker stop drp &2>/dev/null  && \
	docker rm --force $(shell docker ps -qa) 

.PHONY: clean-nodes
clean-nodes: ## Stop and remove node containers
	@echo "+ $@"
	@$$(docker ps -a | grep -q node); \
	if [ $$? -eq 0 ]; then \
		docker rm --force $(shell docker ps -qa -f name=node);\
	fi
	@for m in $$(docker exec drp /provision/drpcli machines list | jq '.[].Uuid' -r);\
	do docker exec drp /provision/drpcli machines destroy $$m;\
	done

.PHONY: drp-run
drp-run: ## Startup DRP container and bind provisioning interface to br0
	@echo "+ $@"
	@$$(docker ps -a | grep -q drp); \
	if [ $$? -eq 0 ]; then \
		docker stop drp;\
	else\
		docker run --rm -itd -p8092:8092 -p8091:8091 --name drp digitalrebar/provision:stable >/dev/null ; \
		sleep 5; \
		echo "DRP LINK ADDRESS " $(DRP_LINK_ADDR);\
		sudo ./pipework br0 -i eth1 drp $(DRP_LINK_ADDR);\
	fi

.PHONY: drp-uploadiso
drp-uploadiso: ## Upload standard ISOS and set bootenv
	@echo "+ $@"
	@docker exec drp /provision/drpcli bootenvs uploadiso ubuntu-16.04-install 
	@docker exec drp /provision/drpcli bootenvs uploadiso centos-7-install
	@docker exec drp /provision/drpcli bootenvs uploadiso sledgehammer && \
	docker exec drp /provision/drpcli prefs set unknownBootEnv discovery defaultBootEnv sledgehammer defaultStage discover

.PHONY: drp-configure-subnet
drp-configure-subnet:
	@echo "+ $@"
	@docker exec -i drp /provision/drpcli subnets create - < subnet.json

.PHONY: drp-update-profile
drp-update-profile: ## Update Global profile
	@echo "+ $@"
	@docker exec -i drp /provision/drpcli profiles update "global" - < global.json

.PHONY: drp-configure
drp-configure: ## Configure DRP server with iso, bootenv and subnet profile
	make drp-uploadiso
	make drp-configure-subnet
	make drp-update-profile

.PHONY: drp-showlogs
drp-showlogs: ## Watch DRP logs
	@docker exec drp /provision/drpcli logs watch

# get-plugins: SHELL:=/bin/bash
# get-plugins: ## Get DR plugins for IPMI
# 	mkdir -p dr-provision-install && \
#     pushd dr-provision-install

#     # get our packet-ipmi provider plugin location 
#     PACKET_URL="https://qww9e4paf1.execute-api.us-west-2.amazonaws.com/main/catalog/plugins/packet-ipmi${RACKN_AUTH}"
#     PART=`$CURL $PACKET_URL | jq -r ".$DRP_ARCH.$DRP_OS"`
#     BASE=`$CURL $PACKET_URL | jq -r '.base'`
#     # download the plugin - AWS cares about extra slashes ... blech 
#     curl -s ${BASE}${PART} -o drp-plugin-packet-ipmi

#     cd ..
# TODO Check for vncclient

.PHONY: start-vnc
start-vnc:
	@which $(VNCVIEWER); \
	if [ $$? -eq 0 ]; then \
		$(VNCVIEWER) localhost:$(PORT) Encryption=PreferOff&\
	fi

.PHONY: create-nodes
create-nodes:  ## Create Node Simulators <NODES>=integer
ifeq ($(NODES),0)
	NODES=1
endif

	@$$(docker exec drp /provision/drpcli subnets list | grep -q 192.168.1.0/24); \
	if [ $$? -eq 1 ]; then \
		 make drp-configure-subnet;\
	fi;\
	for i in `seq 1 $(NODES)`; do \
		echo "Creating node"$$i;\
		./start-node.sh -c default.yml -n "node"$$i -p"590"$$i;\
	     make start-vnc PORT="590"$$i;\
 	done

.PHONY: drp-isos	
drp-isos: ## Show loaded isos
	@docker exec drp /provision/drpcli isos list

.PHONY: drp-subnets	
drp-subnets: ## Show loaded isos
	docker exec drp /provision/drpcli subnets list

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
