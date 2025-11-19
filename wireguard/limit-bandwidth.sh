#!/bin/bash

# Inspect WG Easy PID
sudo docker inspect wg-easy --format '{{.State.Pid}}'

# Inspect WG Easy Interface
sudo docker exec wg-easy sh -c 'cat /sys/class/net/eth0/iflink'

# Check interface index from previous iflink
grep -l 19 /sys/class/net/veth*/ifindex


# Add limit to interface
sudo tc qdisc add dev veth128b21b parent root handle 1: hfsc default 1
sudo tc class add dev veth128b21b parent 1: classid 1:1 hfsc sc rate 10mbit ul rate 10mbit

# Source: https://www.procustodibus.com/blog/2022/12/limit-wireguard-bandwidth/