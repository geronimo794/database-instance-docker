#/bin/bash

# Push host Caddyfile into the container, validate, then reload (no restart).
# Swarm configs and file bind mounts do not pick up host edits on their own.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

SERVICE_NAME="${CADDY_SERVICE_NAME:-caddy_caddy}"
HOST_CADDYFILE="${HOST_CADDYFILE:-${SCRIPT_DIR}/Caddyfile}"
CONTAINER_CADDYFILE="/tmp/Caddyfile"

if [ ! -s "${HOST_CADDYFILE}" ]; then
	echo "Caddyfile is missing or empty: ${HOST_CADDYFILE}"
	exit 1
fi

CONTAINER_IDS=$(sudo docker ps -q -f "name=${SERVICE_NAME}")

if [ -z "${CONTAINER_IDS}" ]; then
	echo "No running container found for ${SERVICE_NAME}"
	exit 1
fi

for CONTAINER_ID in ${CONTAINER_IDS}; do
	echo "Copying ${HOST_CADDYFILE} into ${CONTAINER_ID}:${CONTAINER_CADDYFILE}"
	sudo docker cp "${HOST_CADDYFILE}" "${CONTAINER_ID}:${CONTAINER_CADDYFILE}"

	echo "Checking Caddyfile in ${CONTAINER_ID}"
	if ! sudo docker exec "${CONTAINER_ID}" caddy validate --config "${CONTAINER_CADDYFILE}" --adapter caddyfile; then
		echo "Caddyfile is invalid; reload aborted"
		exit 1
	fi

	echo "Reloading Caddy in ${CONTAINER_ID}"
	sudo docker exec "${CONTAINER_ID}" caddy reload --config "${CONTAINER_CADDYFILE}" --adapter caddyfile
done

echo "Caddyfile valid; reload complete"
