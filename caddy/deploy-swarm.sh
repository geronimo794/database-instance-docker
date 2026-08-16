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

mkdir -p persistent-data/data persistent-data/config

if [ ! -s Caddyfile ]; then
	echo "Caddyfile is missing or empty"
	exit 1
fi

# Drop leftover Swarm config from earlier deploys (empty configs fail the daemon)
if sudo docker config inspect caddy_caddyfile >/dev/null 2>&1; then
	sudo docker service update --config-rm caddy_caddyfile caddy_caddy >/dev/null 2>&1 || true
	sudo docker config rm caddy_caddyfile >/dev/null 2>&1 || true
fi

envsubst < docker-compose-swarm.yaml > docker-compose-swarm.processed.yaml

# Deploy to swarm
sudo docker stack deploy -c docker-compose-swarm.processed.yaml caddy --detach=false

# Remove the processed docker compose file
rm docker-compose-swarm.processed.yaml

# To show the logs:
# docker service logs caddy_caddy --follow



