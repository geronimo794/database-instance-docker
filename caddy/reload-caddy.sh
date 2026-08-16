#/bin/bash

# Validate Caddyfile, then graceful reload (no container restart).

set -euo pipefail

SERVICE_NAME="${CADDY_SERVICE_NAME:-caddy_caddy}"
CADDYFILE="${CADDYFILE:-/etc/caddy/Caddyfile}"

CONTAINER_IDS=$(sudo docker ps -q -f "name=${SERVICE_NAME}")

if [ -z "${CONTAINER_IDS}" ]; then
	echo "No running container found for ${SERVICE_NAME}"
	exit 1
fi

for CONTAINER_ID in ${CONTAINER_IDS}; do
	echo "Checking Caddyfile in ${CONTAINER_ID}"
	if ! sudo docker exec "${CONTAINER_ID}" caddy validate --config "${CADDYFILE}" --adapter caddyfile; then
		echo "Caddyfile is invalid; reload aborted"
		exit 1
	fi

	echo "Reloading Caddy in ${CONTAINER_ID}"
	sudo docker exec "${CONTAINER_ID}" caddy reload --config "${CADDYFILE}" --adapter caddyfile
done

echo "Caddyfile valid; reload complete"
