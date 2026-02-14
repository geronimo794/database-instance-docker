#/bin/bash

# Show all command and variable value
# set -x

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
# set +x

######################################
# Deploy to swarm
######################################

# Replace all needed variables in the processed docker compose file with all needed variables from .env file
envsubst < docker-compose-swarm.yaml > docker-compose-swarm.processed.yaml

# Deploy to swarm
sudo docker stack deploy -c docker-compose-swarm.processed.yaml traefik --detach=false

# Remove the processed docker compose file
rm docker-compose-swarm.processed.yaml

# To show the logs:
# docker service ps  traefik_traefik --no-trunc