# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)
# SHELL := /bin/bash
# Setup name variables for the package/tool
NAME := drp-test
PKG := github.com/gaberger/$(NAME)

# Set any default go build tags
BUILDTAGS :=

BUILDDIR := ${PREFIX}/cross
DRP_LINK_ADDR := 192.168.1.10/24


# Populate version variables
# Add to compile time flags
VERSION := $(shell cat VERSION.txt)

.DEFAULT_GOAL := help

stop: ## Stop all simulator services
	docker stop drp


git-pull: SHELL:=/bin/bash  
git-pull: ## Pull image from GitHub
	@echo "+ $@"
	@pushd provision && \
	git pull https://github.com/digitalrebar/provision && \
	popd

docker-pull: ## Pull image from docker
	@echo "+ $@"
	@docker stop drp &2>/dev/null && \
	docker pull digitalrebar/provision:latest

download:  ## Git clone repo
	@echo "+ $@"
	@git clone https://github.com/digitalrebar/provision

clean: ## Stop DRP container and pull from from DockerHub
	@echo "+ $@"
	@docker stop drp &2>/dev/null  && \
	docker rm $(shell docker ps -qa) 

clean-nodes: ## Stop node containers
	@echo "+ $@"
	if [ ! -z $(docker ps -q --filter "name=node") ]; then\
		$(shell docker stop $(shell docker ps -q --filter "name=node"));\
	fi

run: ## Startup DRP container and bind provisioninginterface to br0
	@echo "+ $@"
	@docker stop drp | true && \
	docker run --rm -itd -p8092:8092 -p8091:8091 --name drp digitalrebar/provision:latest && \
	sleep 10 && \
	echo $(DRP_LINK_ADDR)
	sudo ./pipework br0 -i eth1 drp $(DRP_LINK_ADDR)

uploadiso: ## Upload standard ISOS and set bootenv
	@echo "+ $@"
	@docker exec drp /provision/drpcli bootenvs uploadiso ubuntu-16.04-install
	@docker exec drp /provision/drpcli bootenvs uploadiso centos-7-install
	@docker exec drp /provision/drpcli bootenvs uploadiso sledgehammer && \
	docker exec drp /provision/drpcli prefs set unknownBootEnv discovery defaultBootEnv sledgehammer defaultStage discover

configure-node-network:
ifeq ($(NODES),0)
	NODES=1
endif

	for i in `seq 1 $(NODES)`; do \
		sudo ./pipework br0 -i eth1 "node"$$i dhclient;\
		docker exec "node"$$i sudo brctl addbr br0;\
		docker exec "node"$$i sudo brctl addif br0 eth1;\
		docker exec "node"$$i ip a;\
	 	docker exec "node"$$i sudo ip a delete 192.168.1.13/24 dev eth1;\
	 	docker exec "node"$$i sudo ip a add  192.168.1.13/24 dev br0;\
		docker exec "node"$$i sudo ip l set br0 up;\
	done


create-nodes:  ## Create Node Simulators <NODES>=integer
ifeq ($(NODES),0)
	NODES=1
endif

	for i in `seq 1 $(NODES)`; do \
		echo "Creating Node"$$i;\
		docker run --rm -itd --name "node"$$i --privileged infrasim-compute  bash;\
	done && \
	make configure-node-network NODES=$(NODES)

isos: ## Show loaded isos
	@docker exec drp /provision/drpcli isos list


.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'