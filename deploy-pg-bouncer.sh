#/bin/bash

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

export NETWORK
export PG_BOUNCER_PORT
export PG_BOUNCER_DATABASE_URLS
docker stack deploy -c docker-compose-pg-bouncer.yaml pgbouncer --detach=false