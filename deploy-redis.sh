#/bin/bash

# Make sure run as sudo su
# sudo su

# Show all command and variable value
set -x
# Load configuration from .env file
set -o allexport
# If .env not exist then use format.env
if [ -f .env ]; then
	source .env
else
	echo "Please populate the .env file from .env.format"
	exit
fi
set +o allexport

# Hide all command and variable value again
set +x

export REDIS_USERNAME
export REDIS_PASSWORD
export REDIS_INSIGHT_PORT
export NETWORK

docker stack deploy -c docker-compose-redis.yaml redis