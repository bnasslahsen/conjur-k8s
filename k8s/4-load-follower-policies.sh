#!/bin/bash

set -a
source "./../.env"
set +a

#Load follower policy
envsubst < policies/follower-host.yml > follower-host.yml.tmp
conjur policy update -b root -f follower-host.yml.tmp
rm follower-host.yml.tmp